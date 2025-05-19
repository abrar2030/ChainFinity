import numpy as np
from typing import Dict, List, Union, Optional
import math

class APYCalculator:
    """
    APY (Annual Percentage Yield) Calculator for DeFi protocols
    
    This class provides methods to calculate APY for various DeFi protocols
    including lending platforms, liquidity pools, staking, and yield farming.
    """
    
    def __init__(self, compounding_frequency: int = 365):
        """
        Initialize the APY Calculator
        
        Args:
            compounding_frequency: Number of compounding periods per year (default: 365 for daily)
        """
        self.compounding_frequency = compounding_frequency
    
    def calculate_lending_apy(self, apr: float) -> float:
        """
        Calculate APY for lending protocols based on APR
        
        Args:
            apr: Annual Percentage Rate (decimal, e.g., 0.05 for 5%)
            
        Returns:
            APY as a decimal value
        """
        return ((1 + (apr / self.compounding_frequency)) ** self.compounding_frequency) - 1
    
    def calculate_lp_apy(
        self, 
        fee_apr: float, 
        token_incentives_apr: Optional[float] = 0, 
        token_appreciation: Optional[float] = 0,
        impermanent_loss_estimate: Optional[float] = 0
    ) -> Dict[str, float]:
        """
        Calculate APY for liquidity pools including fees, incentives, and impermanent loss
        
        Args:
            fee_apr: Annual fee returns from the pool (decimal)
            token_incentives_apr: Additional APR from token rewards (decimal)
            token_appreciation: Estimated token appreciation (decimal)
            impermanent_loss_estimate: Estimated impermanent loss (decimal, negative value)
            
        Returns:
            Dictionary with base_apy, total_apy, and components
        """
        base_apy = self.calculate_lending_apy(fee_apr)
        incentives_apy = self.calculate_lending_apy(token_incentives_apr) if token_incentives_apr > 0 else 0
        
        # Total APY calculation including all components
        total_apy = (1 + base_apy) * (1 + incentives_apy) * (1 + token_appreciation) * (1 + impermanent_loss_estimate) - 1
        
        return {
            "base_apy": base_apy,
            "incentives_apy": incentives_apy,
            "token_appreciation": token_appreciation,
            "impermanent_loss": impermanent_loss_estimate,
            "total_apy": total_apy
        }
    
    def calculate_staking_apy(
        self, 
        staking_rate: float, 
        token_appreciation: Optional[float] = 0
    ) -> Dict[str, float]:
        """
        Calculate APY for staking protocols
        
        Args:
            staking_rate: Annual staking reward rate (decimal)
            token_appreciation: Estimated token appreciation (decimal)
            
        Returns:
            Dictionary with staking_apy, total_apy including appreciation
        """
        staking_apy = self.calculate_lending_apy(staking_rate)
        total_apy = (1 + staking_apy) * (1 + token_appreciation) - 1
        
        return {
            "staking_apy": staking_apy,
            "token_appreciation": token_appreciation,
            "total_apy": total_apy
        }
    
    def calculate_yield_farming_apy(
        self, 
        base_apr: float,
        reward_token_apr: float,
        reward_token_appreciation: Optional[float] = 0,
        platform_token_apr: Optional[float] = 0,
        platform_token_appreciation: Optional[float] = 0
    ) -> Dict[str, float]:
        """
        Calculate APY for yield farming strategies with multiple reward tokens
        
        Args:
            base_apr: Base APR from the protocol (decimal)
            reward_token_apr: APR from reward tokens (decimal)
            reward_token_appreciation: Estimated reward token appreciation (decimal)
            platform_token_apr: APR from platform tokens (decimal)
            platform_token_appreciation: Estimated platform token appreciation (decimal)
            
        Returns:
            Dictionary with base_apy, reward_apy, platform_apy, and total_apy
        """
        base_apy = self.calculate_lending_apy(base_apr)
        
        # Calculate reward token component
        reward_apy = self.calculate_lending_apy(reward_token_apr)
        reward_total = (1 + reward_apy) * (1 + reward_token_appreciation) - 1
        
        # Calculate platform token component
        platform_apy = self.calculate_lending_apy(platform_token_apr) if platform_token_apr > 0 else 0
        platform_total = (1 + platform_apy) * (1 + platform_token_appreciation) - 1 if platform_token_apr > 0 else 0
        
        # Calculate total APY
        total_apy = (1 + base_apy) * (1 + reward_total) * (1 + platform_total) - 1
        
        return {
            "base_apy": base_apy,
            "reward_token_apy": reward_total,
            "platform_token_apy": platform_total,
            "total_apy": total_apy
        }
    
    def calculate_impermanent_loss(self, price_ratio: float) -> float:
        """
        Calculate impermanent loss for a liquidity pool based on price change ratio
        
        Args:
            price_ratio: Ratio of final price to initial price
            
        Returns:
            Impermanent loss as a decimal (negative value)
        """
        # Formula: IL = 2 * sqrt(price_ratio) / (1 + price_ratio) - 1
        return (2 * math.sqrt(price_ratio) / (1 + price_ratio)) - 1
    
    def calculate_optimal_compound_frequency(self, apr: float, gas_cost_usd: float, investment_usd: float) -> Dict[str, Union[int, float]]:
        """
        Calculate the optimal compounding frequency based on gas costs
        
        Args:
            apr: Annual Percentage Rate (decimal)
            gas_cost_usd: Gas cost per compounding action in USD
            investment_usd: Total investment amount in USD
            
        Returns:
            Dictionary with optimal_frequency and optimal_apy
        """
        # Start with daily compounding as a baseline
        best_apy = self.calculate_lending_apy(apr)
        best_frequency = 365
        best_net_return = investment_usd * best_apy - (gas_cost_usd * 365)
        
        # Test different frequencies
        for frequency in [1, 4, 12, 24, 52, 365]:
            apy = ((1 + (apr / frequency)) ** frequency) - 1
            net_return = investment_usd * apy - (gas_cost_usd * frequency)
            
            if net_return > best_net_return:
                best_net_return = net_return
                best_apy = apy
                best_frequency = frequency
        
        return {
            "optimal_frequency": best_frequency,
            "optimal_apy": best_apy,
            "net_annual_return_usd": best_net_return,
            "gas_costs_usd": gas_cost_usd * best_frequency
        }
    
    def format_apy_percentage(self, apy: float, decimals: int = 2) -> str:
        """
        Format APY as a percentage string
        
        Args:
            apy: APY as a decimal value
            decimals: Number of decimal places to display
            
        Returns:
            Formatted percentage string
        """
        return f"{apy * 100:.{decimals}f}%"
    
    def compare_investment_strategies(self, strategies: List[Dict[str, Union[str, float]]]) -> Dict[str, Dict[str, Union[str, float]]]:
        """
        Compare multiple investment strategies based on APY and risk
        
        Args:
            strategies: List of dictionaries containing strategy details
                Each dictionary should have:
                - name: Strategy name
                - apy: Expected APY (decimal)
                - risk_score: Risk score (1-10)
                - investment_usd: Investment amount in USD
                
        Returns:
            Dictionary with strategy comparisons and recommendations
        """
        if not strategies:
            return {"error": "No strategies provided"}
        
        # Calculate expected returns
        for strategy in strategies:
            strategy["annual_return_usd"] = strategy["investment_usd"] * strategy["apy"]
            strategy["risk_adjusted_return"] = strategy["annual_return_usd"] / strategy["risk_score"]
        
        # Find best strategies by different metrics
        best_apy = max(strategies, key=lambda x: x["apy"])
        best_risk_adjusted = max(strategies, key=lambda x: x["risk_adjusted_return"])
        lowest_risk = min(strategies, key=lambda x: x["risk_score"])
        
        return {
            "strategies": strategies,
            "best_apy": {
                "name": best_apy["name"],
                "apy": self.format_apy_percentage(best_apy["apy"]),
                "annual_return_usd": best_apy["annual_return_usd"]
            },
            "best_risk_adjusted": {
                "name": best_risk_adjusted["name"],
                "apy": self.format_apy_percentage(best_risk_adjusted["apy"]),
                "risk_score": best_risk_adjusted["risk_score"],
                "risk_adjusted_return": best_risk_adjusted["risk_adjusted_return"]
            },
            "lowest_risk": {
                "name": lowest_risk["name"],
                "apy": self.format_apy_percentage(lowest_risk["apy"]),
                "risk_score": lowest_risk["risk_score"]
            }
        }
