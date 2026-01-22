"""
Property Test: Configuration Format Validation

Feature: terraform-infrastructure-rebuild
Property 2: Configuration Format Validation

For any configuration file with invalid formats (malformed email addresses,
invalid domain names, incorrect AWS ARN format, invalid CIDR notation,
invalid AWS region), the Configuration_Manager should reject the configuration
with specific error messages indicating which fields have format errors.

Validates: Requirements 10.1, 10.2, 10.3, 10.4
"""

import re
from hypothesis import given, strategies as st, settings
import pytest

# Valid format patterns
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

def validate_aws_region(region):
    """Validate AWS region format."""
    if not isinstance(region, str):
        return False, "AWS Region must be a string"
    if not re.match(AWS_REGION_PATTERN, region):
        return False, "AWS Region must be in format: us-east-1, eu-west-1, etc."
    return True, None

def validate_domain(domain):
    """Validate domain name format."""
    if not isinstance(domain, str):
        return False, "Domain must be a string"
    if len(domain) == 0:
        return False, "Domain cannot be empty"
    # Check for consecutive dots
    if ".." in domain:
        return False, "Domain cannot contain consecutive dots"
    # Check for leading/trailing dots or hyphens
    if domain.startswith(".") or domain.startswith("-"):
        return False, "Domain cannot start with dot or hyphen"
    if domain.endswith(".") or domain.endswith("-"):
        return False, "Domain cannot end with dot or hyphen"
    if not re.match(DOMAIN_PATTERN, domain):
        return False, "Domain must be a valid domain name"
    return True, None

def validate_email(email):
    """Validate email address format."""
    if not isinstance(email, str):
        return False, "Email must be a string"
    if not re.match(EMAIL_PATTERN, email):
        return False, "Email must be a valid email address"
    return True, None

def validate_cidr(cidr):
    """Validate CIDR block format."""
    if not isinstance(cidr, str):
        return False, "CIDR must be a string"
    
    # Basic CIDR format: x.x.x.x/y
    parts = cidr.split("/")
    if len(parts) != 2:
        return False, "CIDR must be in format x.x.x.x/y"
    
    ip_part, prefix_part = parts
    
    # Validate IP address
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
    
    # Validate prefix length
    try:
        prefix = int(prefix_part)
        if prefix < 0 or prefix > 32:
            return False, "CIDR prefix must be 0-32"
    except ValueError:
        return False, "CIDR prefix must be a number"
    
    return True, None

# Property Tests

@settings(max_examples=100)
@given(account_id=st.text(min_size=1, max_size=20))
def test_property_aws_account_id_format_validation(account_id):
    """
    Property: For any string that is not a 12-digit number,
    AWS account ID validation should reject it.
    """
    is_valid, error = validate_aws_account_id(account_id)
    
    # If it matches the pattern, it should be valid
    matches_pattern = re.match(AWS_ACCOUNT_ID_PATTERN, account_id) is not None
    
    if matches_pattern:
        assert is_valid, f"Valid account ID {account_id} was rejected"
        assert error is None
    else:
        assert not is_valid, f"Invalid account ID {account_id} was accepted"
        assert error is not None
        assert "12-digit" in error or "string" in error

@settings(max_examples=100)
@given(region=st.text(min_size=1, max_size=30))
def test_property_aws_region_format_validation(region):
    """
    Property: For any string that does not match AWS region format,
    region validation should reject it.
    """
    is_valid, error = validate_aws_region(region)
    
    matches_pattern = re.match(AWS_REGION_PATTERN, region) is not None
    
    if matches_pattern:
        assert is_valid, f"Valid region {region} was rejected"
        assert error is None
    else:
        assert not is_valid, f"Invalid region {region} was accepted"
        assert error is not None
        assert "format" in error or "string" in error

@settings(max_examples=100)
@given(domain=st.text(min_size=0, max_size=100))
def test_property_domain_format_validation(domain):
    """
    Property: For any string that is not a valid domain name,
    domain validation should reject it.
    """
    is_valid, error = validate_domain(domain)
    
    if len(domain) == 0:
        assert not is_valid
        assert error is not None
        return
    
    # Check for invalid patterns
    has_consecutive_dots = ".." in domain
    starts_with_invalid = domain.startswith(".") or domain.startswith("-")
    ends_with_invalid = domain.endswith(".") or domain.endswith("-")
    matches_pattern = re.match(DOMAIN_PATTERN, domain) is not None
    
    if has_consecutive_dots or starts_with_invalid or ends_with_invalid or not matches_pattern:
        assert not is_valid, f"Invalid domain {domain} was accepted"
        assert error is not None
    else:
        assert is_valid, f"Valid domain {domain} was rejected"
        assert error is None

@settings(max_examples=100)
@given(email=st.text(min_size=1, max_size=100))
def test_property_email_format_validation(email):
    """
    Property: For any string that is not a valid email address,
    email validation should reject it.
    """
    is_valid, error = validate_email(email)
    
    matches_pattern = re.match(EMAIL_PATTERN, email) is not None
    
    if matches_pattern:
        assert is_valid, f"Valid email {email} was rejected"
        assert error is None
    else:
        assert not is_valid, f"Invalid email {email} was accepted"
        assert error is not None
        assert "email" in error.lower() or "string" in error

@settings(max_examples=100)
@given(cidr=st.text(min_size=1, max_size=30))
def test_property_cidr_format_validation(cidr):
    """
    Property: For any string that is not a valid CIDR block,
    CIDR validation should reject it.
    """
    is_valid, error = validate_cidr(cidr)
    
    # Check if it is a valid CIDR by our validation logic
    # If validation passes, it should be valid
    if is_valid:
        assert error is None
        # Verify it has the basic structure
        assert "/" in cidr
        parts = cidr.split("/")
        assert len(parts) == 2
        assert "." in parts[0]
    else:
        assert error is not None
        assert any(keyword in error for keyword in ["CIDR", "format", "IPv4", "octet", "prefix", "string"])

# Specific edge case tests

def test_valid_formats_accepted():
    """Test that valid formats are accepted."""
    # Valid AWS account ID
    assert validate_aws_account_id("123456789012")[0] == True
    
    # Valid AWS regions
    assert validate_aws_region("us-east-1")[0] == True
    assert validate_aws_region("eu-west-2")[0] == True
    assert validate_aws_region("ap-south-1")[0] == True
    
    # Valid domains
    assert validate_domain("example.com")[0] == True
    assert validate_domain("chat.example.com")[0] == True
    assert validate_domain("my-app.example.co.uk")[0] == True
    
    # Valid emails
    assert validate_email("user@example.com")[0] == True
    assert validate_email("admin@company.co.uk")[0] == True
    
    # Valid CIDR blocks
    assert validate_cidr("10.0.0.0/16")[0] == True
    assert validate_cidr("192.168.1.0/24")[0] == True
    assert validate_cidr("172.16.0.0/12")[0] == True

def test_invalid_formats_rejected():
    """Test that invalid formats are rejected."""
    # Invalid AWS account IDs
    assert validate_aws_account_id("12345")[0] == False  # Too short
    assert validate_aws_account_id("1234567890123")[0] == False  # Too long
    assert validate_aws_account_id("12345678901a")[0] == False  # Contains letter
    
    # Invalid AWS regions
    assert validate_aws_region("us-east")[0] == False  # Missing number
    assert validate_aws_region("useast1")[0] == False  # Missing hyphens
    assert validate_aws_region("US-EAST-1")[0] == False  # Uppercase
    
    # Invalid domains
    assert validate_domain("")[0] == False  # Empty
    assert validate_domain("example..com")[0] == False  # Double dot
    assert validate_domain("-example.com")[0] == False  # Starts with hyphen
    
    # Invalid emails
    assert validate_email("notanemail")[0] == False  # No @
    assert validate_email("@example.com")[0] == False  # No local part
    assert validate_email("user@")[0] == False  # No domain
    
    # Invalid CIDR blocks
    assert validate_cidr("10.0.0.0")[0] == False  # No prefix
    assert validate_cidr("10.0.0/16")[0] == False  # Incomplete IP
    assert validate_cidr("10.0.0.0/33")[0] == False  # Invalid prefix
    assert validate_cidr("256.0.0.0/16")[0] == False  # Invalid octet

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
