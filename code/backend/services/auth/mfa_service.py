"""
Multi-Factor Authentication (MFA) Service
Handles TOTP-based two-factor authentication
"""

import logging

import pyotp

logger = logging.getLogger(__name__)


class MFAService:
    """
    MFA service for TOTP-based two-factor authentication
    """

    @staticmethod
    def generate_secret() -> str:
        """
        Generate a new TOTP secret
        """
        return pyotp.random_base32()

    @staticmethod
    def generate_qr_code(secret: str, email: str, issuer: str = "ChainFinity") -> str:
        """
        Generate QR code URL for authenticator apps
        """
        totp = pyotp.TOTP(secret)
        provisioning_uri = totp.provisioning_uri(name=email, issuer_name=issuer)
        return provisioning_uri

    @staticmethod
    def verify_code(secret: str, code: str) -> bool:
        """
        Verify a TOTP code
        """
        try:
            totp = pyotp.TOTP(secret)
            return totp.verify(code, valid_window=1)
        except Exception as e:
            logger.error(f"MFA verification error: {e}")
            return False

    @staticmethod
    def generate_backup_codes(count: int = 10) -> list:
        """
        Generate backup codes for account recovery
        """
        import secrets

        codes = []
        for _ in range(count):
            code = "-".join([secrets.token_hex(2).upper() for _ in range(3)])
            codes.append(code)
        return codes

    @staticmethod
    def get_current_code(secret: str) -> str:
        """
        Get current TOTP code (for testing purposes)
        """
        totp = pyotp.TOTP(secret)
        return totp.now()
