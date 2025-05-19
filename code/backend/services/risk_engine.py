import numpy as np
import pandas as pd
from scipy.stats import multivariate_normal, norm
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import StandardScaler
import datetime
import logging

logger = logging.getLogger(__name__)

class EnhancedRiskEngine:
    """
    Enhanced risk calculation engine with advanced risk scoring, 
    real-time market data integration, stress testing, and alerts
    """
    
    def __init__(self):
        self.risk_thresholds = {
            'low': 0.05,
            'medium': 0.10,
            'high': 0.15,
            'critical': 0.20
        }
        self.correlation_matrix = None
        self.volatility_data = {}
        self.market_data = {}
        self.last_update = None
        self.alert_subscribers = []
        
    def calculate_var(self, returns, confidence=0.95, method='parametric', time_horizon=1):
        """
        Calculate Value-at-Risk using multiple methods
        
        Parameters:
        - returns: numpy array of historical returns
        - confidence: confidence level (default: 0.95)
        - method: 'parametric', 'historical', or 'monte_carlo'
        - time_horizon: time horizon in days
        
        Returns:
        - VaR value
        """
        if method == 'parametric':
            mu = np.mean(returns)
            sigma = np.std(returns)
            var = norm.ppf(1-confidence) * sigma * np.sqrt(time_horizon) + mu * time_horizon
            return -var
            
        elif method == 'historical':
            if len(returns) < 100:
                logger.warning("Historical VaR calculation with less than 100 data points")
            return -np.percentile(returns, 100 * (1-confidence)) * np.sqrt(time_horizon)
            
        elif method == 'monte_carlo':
            mu = np.mean(returns)
            sigma = np.std(returns)
            simulations = 10000
            sim_returns = np.random.normal(mu * time_horizon, sigma * np.sqrt(time_horizon), simulations)
            return -np.percentile(sim_returns, 100 * (1-confidence))
        
        else:
            raise ValueError(f"Unknown VaR method: {method}")
    
    def calculate_cvar(self, returns, confidence=0.95):
        """
        Calculate Conditional Value-at-Risk (Expected Shortfall)
        
        Parameters:
        - returns: numpy array of historical returns
        - confidence: confidence level (default: 0.95)
        
        Returns:
        - CVaR value
        """
        var = self.calculate_var(returns, confidence, 'historical')
        return -np.mean(returns[returns <= -var])
    
    def portfolio_risk(self, weights, cov_matrix):
        """
        Calculate portfolio volatility using Markowitz model
        
        Parameters:
        - weights: numpy array of asset weights
        - cov_matrix: covariance matrix of asset returns
        
        Returns:
        - Portfolio volatility
        """
        return np.sqrt(np.dot(weights.T, np.dot(cov_matrix, weights)))
    
    def portfolio_sharpe_ratio(self, weights, returns, risk_free_rate=0.02):
        """
        Calculate portfolio Sharpe ratio
        
        Parameters:
        - weights: numpy array of asset weights
        - returns: pandas DataFrame of asset returns
        - risk_free_rate: annual risk-free rate (default: 0.02)
        
        Returns:
        - Sharpe ratio
        """
        portfolio_return = np.sum(returns.mean() * weights) * 252  # Annualized
        portfolio_vol = self.portfolio_risk(weights, returns.cov() * 252)
        return (portfolio_return - risk_free_rate) / portfolio_vol
    
    def stress_test(self, portfolio, scenarios):
        """
        Run comprehensive scenario-based stress testing
        
        Parameters:
        - portfolio: dict with asset names as keys and weights as values
        - scenarios: list of scenario dicts with 'name', 'description', and asset shocks
        
        Returns:
        - Dictionary of stress test results
        """
        results = {}
        portfolio_value = sum(portfolio.values())
        
        for scenario in scenarios:
            scenario_impact = 0
            asset_impacts = {}
            
            for asset, value in portfolio.items():
                if asset in scenario:
                    shock = scenario[asset]
                    impact = value * shock
                    scenario_impact += impact
                    asset_impacts[asset] = {
                        'value': value,
                        'shock': shock,
                        'impact': impact
                    }
            
            results[scenario['name']] = {
                'description': scenario['description'],
                'total_impact': scenario_impact,
                'impact_percentage': scenario_impact / portfolio_value,
                'asset_impacts': asset_impacts
            }
            
        return results
    
    def calculate_correlation(self, returns_df):
        """
        Calculate and store correlation matrix between assets
        
        Parameters:
        - returns_df: pandas DataFrame of asset returns
        """
        self.correlation_matrix = returns_df.corr()
        return self.correlation_matrix
    
    def update_market_data(self, asset_prices):
        """
        Update market data and calculate volatility
        
        Parameters:
        - asset_prices: dict with asset names as keys and price time series as values
        """
        self.last_update = datetime.datetime.now()
        
        for asset, prices in asset_prices.items():
            if len(prices) > 1:
                # Calculate returns
                returns = np.diff(prices) / prices[:-1]
                
                # Update volatility using exponentially weighted moving average
                if asset in self.volatility_data:
                    lambda_factor = 0.94  # EWMA decay factor
                    current_vol = self.volatility_data[asset]
                    latest_return = returns[-1]
                    new_vol = np.sqrt(lambda_factor * current_vol**2 + (1-lambda_factor) * latest_return**2)
                    self.volatility_data[asset] = new_vol
                else:
                    self.volatility_data[asset] = np.std(returns)
                
                self.market_data[asset] = {
                    'current_price': prices[-1],
                    'daily_change': (prices[-1] / prices[-2] - 1) if len(prices) > 1 else 0,
                    'volatility': self.volatility_data[asset]
                }
    
    def risk_score(self, portfolio, market_conditions=None):
        """
        Calculate comprehensive risk score for a portfolio
        
        Parameters:
        - portfolio: dict with asset names as keys and weights as values
        - market_conditions: optional dict with market condition factors
        
        Returns:
        - Risk score (0-100) and risk category
        """
        if not self.market_data:
            raise ValueError("Market data not available. Call update_market_data first.")
        
        # Base score from portfolio volatility
        assets = list(portfolio.keys())
        weights = np.array([portfolio[asset] for asset in assets])
        
        # Create volatility matrix
        vol_vector = np.array([self.volatility_data.get(asset, 0.2) for asset in assets])
        diag_vol = np.diag(vol_vector)
        
        # Use stored correlation matrix or identity if not available
        if self.correlation_matrix is not None:
            corr_matrix = self.correlation_matrix.loc[assets, assets].values
        else:
            corr_matrix = np.identity(len(assets))
        
        # Calculate covariance matrix
        cov_matrix = np.dot(np.dot(diag_vol, corr_matrix), diag_vol)
        
        # Calculate portfolio volatility
        portfolio_vol = self.portfolio_risk(weights, cov_matrix)
        vol_score = min(100, portfolio_vol * 500)  # Scale to 0-100
        
        # Concentration risk
        concentration = np.sum(weights**2) * len(weights)  # Herfindahl index normalized
        concentration_score = min(100, concentration * 50)
        
        # Market condition adjustment
        market_score = 50  # Neutral by default
        if market_conditions:
            vix = market_conditions.get('vix', 20)
            market_score = min(100, vix * 2.5)
        
        # Combine scores with weights
        final_score = 0.5 * vol_score + 0.3 * concentration_score + 0.2 * market_score
        
        # Determine risk category
        if final_score < 25:
            category = 'low'
        elif final_score < 50:
            category = 'medium'
        elif final_score < 75:
            category = 'high'
        else:
            category = 'critical'
            
        return {
            'score': final_score,
            'category': category,
            'components': {
                'volatility': vol_score,
                'concentration': concentration_score,
                'market_conditions': market_score
            }
        }
    
    def check_risk_alerts(self, portfolio, previous_score=None):
        """
        Check for risk alerts based on current portfolio risk
        
        Parameters:
        - portfolio: dict with asset names as keys and weights as values
        - previous_score: previous risk score for comparison
        
        Returns:
        - List of alert dictionaries
        """
        alerts = []
        
        try:
            risk_result = self.risk_score(portfolio)
            current_score = risk_result['score']
            
            # Alert on high absolute risk
            if risk_result['category'] in ['high', 'critical']:
                alerts.append({
                    'level': 'warning',
                    'message': f"Portfolio risk level is {risk_result['category']} ({current_score:.1f}/100)",
                    'timestamp': datetime.datetime.now()
                })
            
            # Alert on significant risk increase
            if previous_score and (current_score - previous_score) > 15:
                alerts.append({
                    'level': 'alert',
                    'message': f"Risk score increased significantly: {previous_score:.1f} → {current_score:.1f}",
                    'timestamp': datetime.datetime.now()
                })
                
            # Check for high concentration
            if risk_result['components']['concentration'] > 70:
                alerts.append({
                    'level': 'info',
                    'message': "Portfolio has high concentration risk",
                    'timestamp': datetime.datetime.now()
                })
                
            # Notify subscribers
            for subscriber in self.alert_subscribers:
                subscriber(alerts)
                
        except Exception as e:
            logger.error(f"Error checking risk alerts: {str(e)}")
            
        return alerts
    
    def subscribe_to_alerts(self, callback):
        """
        Subscribe to risk alerts
        
        Parameters:
        - callback: function to call with alerts
        """
        self.alert_subscribers.append(callback)
        
    def unsubscribe_from_alerts(self, callback):
        """
        Unsubscribe from risk alerts
        
        Parameters:
        - callback: function to remove from subscribers
        """
        if callback in self.alert_subscribers:
            self.alert_subscribers.remove(callback)
            
    def generate_risk_report(self, portfolio, returns_df=None):
        """
        Generate comprehensive risk report
        
        Parameters:
        - portfolio: dict with asset names as keys and weights as values
        - returns_df: optional pandas DataFrame of historical returns
        
        Returns:
        - Dictionary with risk report data
        """
        report = {
            'timestamp': datetime.datetime.now(),
            'portfolio_composition': portfolio,
            'risk_metrics': {}
        }
        
        # Add risk score
        try:
            report['risk_score'] = self.risk_score(portfolio)
        except Exception as e:
            report['risk_score'] = {'error': str(e)}
            
        # Add market data
        report['market_data'] = self.market_data
        
        # Add historical metrics if returns data provided
        if returns_df is not None:
            weights = np.array([portfolio.get(asset, 0) for asset in returns_df.columns])
            weights = weights / np.sum(weights)  # Normalize weights
            
            # Calculate portfolio returns
            portfolio_returns = returns_df.dot(weights)
            
            report['risk_metrics'] = {
                'volatility': portfolio_returns.std() * np.sqrt(252),  # Annualized
                'var_95': self.calculate_var(portfolio_returns.values, 0.95),
                'cvar_95': self.calculate_cvar(portfolio_returns.values, 0.95),
                'max_drawdown': self._calculate_max_drawdown(portfolio_returns),
                'sharpe_ratio': self.portfolio_sharpe_ratio(weights, returns_df),
                'correlation_matrix': returns_df.corr().to_dict() if len(returns_df.columns) > 1 else {}
            }
            
        return report
    
    def _calculate_max_drawdown(self, returns):
        """
        Calculate maximum drawdown from returns
        
        Parameters:
        - returns: pandas Series of returns
        
        Returns:
        - Maximum drawdown value
        """
        wealth_index = (1 + returns).cumprod()
        previous_peaks = wealth_index.cummax()
        drawdowns = (wealth_index - previous_peaks) / previous_peaks
        return drawdowns.min()
