import numpy as np
import pandas as pd
import tensorflow as tf


class CorrelationPredictor:
    def __init__(self):
        self.model = tf.keras.Sequential(
            [
                tf.keras.layers.LSTM(64, input_shape=(30, 10)),
                tf.keras.layers.Dense(32, activation="relu"),
                tf.keras.layers.Dense(10, activation="sigmoid"),
            ]
        )
        self.model.compile(optimizer="adam", loss="mse")

    def train(self, data_path):
        df = pd.read_csv(data_path)
        X, y = self.create_sequences(df)
        self.model.fit(X, y, epochs=100, validation_split=0.2)
        self.model.save("correlation_model.h5")

    def create_sequences(self, data):
        # Advanced windowing with volatility adjustment
        sequences = []
        for i in range(30, len(data)):
            seq = data.iloc[i - 30 : i]
            seq = self.add_volatility_features(seq)
            sequences.append(seq.values)
        return np.array(sequences), data.iloc[30:].values
