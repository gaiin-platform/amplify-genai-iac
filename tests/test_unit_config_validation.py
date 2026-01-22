"""
Unit Tests: Configuration Validation

Feature: terraform-infrastructure-rebuild
Tests specific examples and edge cases for configuration validation.

Validates: Requirements 1.2, 10.1, 10.2, 10.3, 10.4
"""

import re
import pytest

# Import validation functions from property test
# In a real implementation, these would be in a shared module
AWS_ACCOUNT_ID_PATTERN = r"^[0-9]{12}$"
AWS_REGION_PATTERN = r"^[a-z]{2}-[a-z]+-[0-9]$"
DOMAIN_PATTERN = r"^[a-z0-9][a-z0-9-\.]*[a-z0-9]$"
EMAIL_PATTERN = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"

def validate_aws_account_id(account_id):
    """Validate AWS account ID format."""
    if not isinstance(account_id, str):
        return False, "AWS Account ID must be a string"
    if not re.match(AWS_ACCOUNT_ID_PATTERN, account_id):
        return False, "AWS Account ID must be a 12-digit number"
    return True, None

def validate_domain(domain):
    """Validate domain name format."""
    if not isinstance(domain, str):
        return False, "Domain must be a string"
    if len(domain) == 0:
        return False, "Domain cannot be empty"
    if ".." in domain:
        return False, "Domain cannot contain consecutive dots"
    if domain.startswith(".") or domain.startswith("-"):
        return False, "Domain cannot start with dot or hyphen"
    if domain.endswith(".") or domain.endswith("-"):
        return False, "Domain cannot end with dot or hyphen"
    if not re.match(DOMAIN_PATTERN, domain):
        return False, "Domain must be a valid domain name"
    return True, None

def validate_cidr(cidr):
    """Validate CIDR block format."""
    if not isinstance(cidr, str):
        return False, "CIDR must be a string"
    
    parts = cidr.split("/")
    if len(parts) != 2:
        return False, "CIDR must be in format x.x.x.x/y"
    
    ip_part, prefix_part = parts
    
    ip_octets = ip_part.split(".")
    if len(ip_octets) != 4:
        return False, "CIDR must have valid IPv4 address"
    
    try:
        for octet in ip_octets:
            val = int(octet)
            if val < 0 or val > 255:
                return False, "CIDR octets must be 0-255"
    except ValueError:
        return False, "CIDR octets must be numbers"
    
    try:
        prefix = int(prefix_part)
        if prefix < 0 or prefix > 32:
            return False, "CIDR prefix must be 0-32"
    except ValueError:
        return False, "CIDR prefix must be a number"
    
    return True, None

# Unit Tests for AWS Account ID

class TestAWSAccountIDValidation:
    """Test AWS Account ID validation with specific examples."""
    
    def test_valid_account_id_accepted(self):
        """Valid 12-digit AWS account ID should be accepted."""
        is_valid, error = validate_aws_account_id("123456789012")
        assert is_valid == True
        assert error is None
    
    def test_valid_account_id_with_zeros(self):
        """Valid account ID with leading zeros should be accepted."""
        is_valid, error = validate_aws_account_id("000000000001")
        assert is_valid == True
        assert error is None
    
    def test_invalid_account_id_too_short(self):
        """Account ID with fewer than 12 digits should be rejected."""
        is_valid, error = validate_aws_account_id("12345")
        assert is_valid == False
        assert error is not None
        assert "12-digit" in error
    
    def test_invalid_account_id_too_long(self):
        """Account ID with more than 12 digits should be rejected."""
        is_valid, error = validate_aws_account_id("1234567890123")
        assert is_valid == False
        assert error is not None
        assert "12-digit" in error
    
    def test_invalid_account_id_with_letters(self):
        """Account ID containing letters should be rejected."""
        is_valid, error = validate_aws_account_id("12345678901a")
        assert is_valid == False
        assert error is not None
        assert "12-digit" in error
    
    def test_invalid_account_id_with_special_chars(self):
        """Account ID with special characters should be rejected."""
        is_valid, error = validate_aws_account_id("123456-78901")
        assert is_valid == False
        assert error is not None
    
    def test_invalid_account_id_empty_string(self):
        """Empty string should be rejected."""
        is_valid, error = validate_aws_account_id("")
        assert is_valid == False
        assert error is not None

# Unit Tests for Domain Name

class TestDomainValidation:
    """Test domain name validation with specific examples."""
    
    def test_valid_simple_domain(self):
        """Simple domain like example.com should be accepted."""
        is_valid, error = validate_domain("example.com")
        assert is_valid == True
        assert error is None
    
    def test_valid_subdomain(self):
        """Subdomain like chat.example.com should be accepted."""
        is_valid, error = validate_domain("chat.example.com")
        assert is_valid == True
        assert error is None
    
    def test_valid_domain_with_hyphens(self):
        """Domain with hyphens should be accepted."""
        is_valid, error = validate_domain("my-app.example.com")
        assert is_valid == True
        assert error is None
    
    def test_valid_multi_level_domain(self):
        """Multi-level domain should be accepted."""
        is_valid, error = validate_domain("app.staging.example.co.uk")
        assert is_valid == True
        assert error is None
    
    def test_invalid_empty_domain(self):
        """Empty domain should be rejected."""
        is_valid, error = validate_domain("")
        assert is_valid == False
        assert error is not None
        assert "empty" in error.lower()
    
    def test_invalid_domain_consecutive_dots(self):
        """Domain with consecutive dots should be rejected."""
        is_valid, error = validate_domain("example..com")
        assert is_valid == False
        assert error is not None
        assert "consecutive" in error.lower()
    
    def test_invalid_domain_starts_with_hyphen(self):
        """Domain starting with hyphen should be rejected."""
        is_valid, error = validate_domain("-example.com")
        assert is_valid == False
        assert error is not None
    
    def test_invalid_domain_ends_with_hyphen(self):
        """Domain ending with hyphen should be rejected."""
        is_valid, error = validate_domain("example.com-")
        assert is_valid == False
        assert error is not None
    
    def test_invalid_domain_starts_with_dot(self):
        """Domain starting with dot should be rejected."""
        is_valid, error = validate_domain(".example.com")
        assert is_valid == False
        assert error is not None

# Unit Tests for CIDR Block

class TestCIDRValidation:
    """Test CIDR block validation with specific examples."""
    
    def test_valid_cidr_class_a(self):
        """Valid Class A CIDR should be accepted."""
        is_valid, error = validate_cidr("10.0.0.0/8")
        assert is_valid == True
        assert error is None
    
    def test_valid_cidr_class_b(self):
        """Valid Class B CIDR should be accepted."""
        is_valid, error = validate_cidr("172.16.0.0/12")
        assert is_valid == True
        assert error is None
    
    def test_valid_cidr_class_c(self):
        """Valid Class C CIDR should be accepted."""
        is_valid, error = validate_cidr("192.168.1.0/24")
        assert is_valid == True
        assert error is None
    
    def test_valid_cidr_slash_16(self):
        """Valid /16 CIDR should be accepted."""
        is_valid, error = validate_cidr("10.0.0.0/16")
        assert is_valid == True
        assert error is None
    
    def test_valid_cidr_slash_32(self):
        """Valid /32 CIDR (single host) should be accepted."""
        is_valid, error = validate_cidr("192.168.1.1/32")
        assert is_valid == True
        assert error is None
    
    def test_invalid_cidr_no_prefix(self):
        """CIDR without prefix should be rejected."""
        is_valid, error = validate_cidr("10.0.0.0")
        assert is_valid == False
        assert error is not None
        assert "format" in error
    
    def test_invalid_cidr_incomplete_ip(self):
        """CIDR with incomplete IP should be rejected."""
        is_valid, error = validate_cidr("10.0.0/16")
        assert is_valid == False
        assert error is not None
        assert "IPv4" in error
    
    def test_invalid_cidr_prefix_too_large(self):
        """CIDR with prefix > 32 should be rejected."""
        is_valid, error = validate_cidr("10.0.0.0/33")
        assert is_valid == False
        assert error is not None
        assert "prefix" in error
    
    def test_invalid_cidr_prefix_negative(self):
        """CIDR with negative prefix should be rejected."""
        is_valid, error = validate_cidr("10.0.0.0/-1")
        assert is_valid == False
        assert error is not None
    
    def test_invalid_cidr_octet_too_large(self):
        """CIDR with octet > 255 should be rejected."""
        is_valid, error = validate_cidr("256.0.0.0/16")
        assert is_valid == False
        assert error is not None
        assert "octet" in error
    
    def test_invalid_cidr_octet_negative(self):
        """CIDR with negative octet should be rejected."""
        is_valid, error = validate_cidr("-1.0.0.0/16")
        assert is_valid == False
        assert error is not None
    
    def test_invalid_cidr_non_numeric_octet(self):
        """CIDR with non-numeric octet should be rejected."""
        is_valid, error = validate_cidr("10.a.0.0/16")
        assert is_valid == False
        assert error is not None
        assert "number" in error

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
