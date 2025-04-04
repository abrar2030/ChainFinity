import numpy as np  
from scipy.stats import multivariate_normal  

class RiskCalculator:  
    def calculate_var(self, returns, confidence=0.95):  
        """Calculate Value-at-Risk using parametric method"""  
        mu = np.mean(returns)  
        sigma = np.std(returns)  
        return mu + sigma * np.percentile(np.random.normal(size=10000), 100*(1-confidence))  

    def portfolio_risk(self, weights, cov_matrix):  
        """Calculate portfolio volatility using Markowitz model"""  
        return np.sqrt(np.dot(weights.T, np.dot(cov_matrix, weights)))  

    def stress_test(self, scenario):  
        """Run scenario-based stress testing"""  
        return {  
            'base_value': scenario['base'],  
            'stress_value': scenario['base'] * (1 + scenario['shock']),  
            'capital_requirement': max(0, scenario['base'] * scenario['shock'])  
        }  