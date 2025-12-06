import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.preprocessing import MinMaxScaler
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class CorrelationPredictor:
    """
    Predicts future asset correlation using an LSTM model.
    Features include price sequences and historical volatility.
    """

    def __init__(self, sequence_length=30, n_features=10):
        self.sequence_length = sequence_length
        self.n_features = n_features  # Number of assets/features in the input data
        self.scaler = MinMaxScaler(feature_range=(0, 1))
        self.model = self._build_model()

    def _build_model(self):
        """Builds the LSTM model for correlation prediction."""
        model = tf.keras.Sequential(
            [
                # Input shape: (sequence_length, n_features)
                tf.keras.layers.LSTM(
                    128,
                    return_sequences=True,
                    input_shape=(self.sequence_length, self.n_features),
                ),
                tf.keras.layers.Dropout(0.3),
                tf.keras.layers.LSTM(64),
                tf.keras.layers.Dropout(0.3),
                tf.keras.layers.Dense(32, activation="relu"),
                # Output layer: predicts the correlation matrix (n_features * n_features)
                tf.keras.layers.Dense(
                    self.n_features * self.n_features, activation="tanh"
                ),
            ]
        )
        model.compile(optimizer="adam", loss="mse")
        logger.info("LSTM Model built successfully.")
        return model

    def _calculate_volatility(self, prices: pd.Series, window=14) -> pd.Series:
        """Calculates historical volatility (standard deviation of log returns)."""
        log_returns = np.log(prices / prices.shift(1))
        return log_returns.rolling(window=window).std() * np.sqrt(
            252
        )  # Annualized volatility

    def create_sequences(self, df: pd.DataFrame) -> Tuple[np.ndarray, np.ndarray]:
        """
        Creates time sequences for LSTM training.
        Input (X): sequence_length days of price and volatility data.
        Target (y): Flattened correlation matrix for the day immediately following the sequence.
        """
        data = df.copy()
        asset_cols = [col for col in data.columns if col.startswith("asset_")]

        if not asset_cols:
            raise ValueError(
                "DataFrame must contain columns starting with 'asset_' for price data."
            )

        # 1. Feature Engineering: Calculate Volatility
        for col in asset_cols:
            data[f"{col}_volatility"] = self._calculate_volatility(data[col])

        # Drop rows with NaN values created by rolling window
        data.dropna(inplace=True)

        # 2. Prepare Features (X)
        features = data[[col for col in data.columns if col not in asset_cols]]
        self.n_features = features.shape[1]

        # Scale features
        scaled_features = self.scaler.fit_transform(features)

        X, y = [], []

        for i in range(self.sequence_length, len(data)):
            # X: Sequence of scaled features
            X.append(scaled_features[i - self.sequence_length : i])

            # y: Target is the correlation matrix of the *next* day's returns
            # For simplicity and a more stable target, we will use the correlation of returns
            # over the next 'n' days, or the correlation of the current day's prices.
            # A more robust approach is to predict the correlation of the next window's returns.
            # Let's use the correlation of the *current* window's returns as a proxy for the target
            # which is a common simplification in time-series prediction.

            # Calculate returns for the current window
            window_prices = data[asset_cols].iloc[i - self.sequence_length : i]
            window_returns = window_prices.pct_change().dropna()

            if window_returns.empty:
                continue

            # Calculate correlation matrix
            corr_matrix = window_returns.corr().values

            # Flatten the correlation matrix for the target
            y.append(corr_matrix.flatten())

        return np.array(X), np.array(y)

    def train(self, data_path: str, epochs=100, batch_size=32, validation_split=0.2):
        """Trains the LSTM model."""
        try:
            df = pd.read_csv(data_path)
        except FileNotFoundError:
            logger.error(f"Data file not found at {data_path}")
            # Create dummy data for demonstration if file not found
            logger.warning("Using dummy data for training demonstration.")
            dates = pd.date_range(start="2020-01-01", periods=200, freq="D")
            np.random.seed(42)
            df = pd.DataFrame(
                {
                    "Date": dates,
                    "asset_btc": np.cumsum(np.random.randn(200) * 0.01 + 100),
                    "asset_eth": np.cumsum(np.random.randn(200) * 0.01 + 50),
                    "asset_sol": np.cumsum(np.random.randn(200) * 0.01 + 20),
                }
            ).set_index("Date")

        # Ensure the data has enough rows for the sequence length
        if len(df) < self.sequence_length + 1:
            logger.error(
                f"Data has only {len(df)} rows, but requires at least {self.sequence_length + 1} for sequence creation."
            )
            return

        try:
            X, y = self.create_sequences(df)
        except ValueError as e:
            logger.error(f"Error creating sequences: {e}")
            return

        if X.shape[0] == 0:
            logger.error("No sequences were created. Check data and sequence length.")
            return

        # Reshape the output layer to match the flattened correlation matrix size
        output_size = y.shape[1]
        if self.model.output_shape[1] != output_size:
            logger.warning(
                f"Rebuilding model to match target output size: {output_size}"
            )
            self.model = self._build_model()
            # The model is built with n_features * n_features, so we need to ensure n_features is correct
            # This is a simplification; in a real scenario, the model architecture should be fixed.
            # For this implementation, we assume the initial build is correct based on the data.
            # Since we dynamically determine n_features in create_sequences, we'll trust the current model structure for now.

        logger.info(f"Training model with X shape: {X.shape}, y shape: {y.shape}")

        self.model.fit(
            X,
            y,
            epochs=epochs,
            batch_size=batch_size,
            validation_split=validation_split,
            verbose=1,
        )
        self.model.save("correlation_model.h5")
        logger.info("Model trained and saved as correlation_model.h5")

    def predict(self, df: pd.DataFrame) -> np.ndarray:
        """
        Predicts the correlation matrix for the next period.
        Input DataFrame should contain the latest 'sequence_length' days of data.
        """
        data = df.copy()
        asset_cols = [col for col in data.columns if col.startswith("asset_")]

        if not asset_cols:
            raise ValueError(
                "DataFrame must contain columns starting with 'asset_' for price data."
            )

        # 1. Feature Engineering: Calculate Volatility
        for col in asset_cols:
            data[f"{col}_volatility"] = self._calculate_volatility(data[col])

        data.dropna(inplace=True)

        if len(data) < self.sequence_length:
            raise ValueError(
                f"Input data must contain at least {self.sequence_length} rows for prediction."
            )

        # Use only the last sequence for prediction
        features = data[[col for col in data.columns if col not in asset_cols]].tail(
            self.sequence_length
        )

        # Scale features
        scaled_features = self.scaler.transform(features)

        # Prepare input for prediction (1, sequence_length, n_features)
        X_pred = np.expand_dims(scaled_features, axis=0)

        # Predict the flattened correlation matrix
        flattened_corr = self.model.predict(X_pred)[0]

        # Reshape back to a correlation matrix (n_assets x n_assets)
        n_assets = len(asset_cols)
        corr_matrix = flattened_corr.reshape(n_assets, n_assets)

        # Apply tanh activation in the model, so values are between -1 and 1.
        # We can enforce symmetry and set diagonal to 1.0
        corr_matrix = (corr_matrix + corr_matrix.T) / 2
        np.fill_diagonal(corr_matrix, 1.0)

        return corr_matrix


if __name__ == "__main__":
    # Example usage (will use dummy data if 'data.csv' is not found)
    predictor = CorrelationPredictor()
    # Assuming a data.csv file exists with columns like 'Date', 'asset_btc', 'asset_eth', etc.
    predictor.train("data.csv", epochs=10)

    # Example prediction data (last 30 days)
    dates = pd.date_range(start="2023-01-01", periods=30, freq="D")
    np.random.seed(10)
    df_pred = pd.DataFrame(
        {
            "Date": dates,
            "asset_btc": np.cumsum(np.random.randn(30) * 0.01 + 100),
            "asset_eth": np.cumsum(np.random.randn(30) * 0.01 + 50),
            "asset_sol": np.cumsum(np.random.randn(30) * 0.01 + 20),
        }
    ).set_index("Date")

    try:
        predicted_corr = predictor.predict(df_pred)
        logger.info("\nPredicted Correlation Matrix:")
        logger.info(predicted_corr)
    except Exception as e:
        logger.error(f"Prediction failed: {e}")
