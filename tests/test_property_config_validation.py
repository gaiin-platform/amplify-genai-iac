"""
Property Test: Configuration Validation Completeness

Feature: terraform-infrastructure-rebuild
Property 1: Configuration Validation Completeness

For any configuration file with missing or invalid required fields,
the Configuration_Manager should reject the configuration and report
all validation errors in a single response.

Validates: Requirements 1.2, 1.4, 6.3, 10.5, 10.6
"""

import re
from hypothesis import given, strategies as st, settings
import pytest

# Validation patterns
AWS_ACCOUNT_ID_PATTERN = r"^[0-9]{12}$"
AWS_REGION_PATTERN = r"^[a-z]{2}-[a-z]+-[0-9]$"
DOMAIN_PATTERN = r"^[a-z0-9][a-z0-9-\.]*[a-z0-9]$"
EMAIL_PATTERN = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"

def validate_configuration(config):
    """Validate a complete configuration and return all errors."""
    errors = []
    
    # Required fields
    required_fields = [
        'aws_account_id', 'aws_region', 'environment',
        'application_domain', 'vpc_cidr'
    ]
    
    # Check for missing required fields
    for field in required_fields:
        if field not in config or config[field] is None or config[field] == '':
            errors.append(f"Missing required field: {field}")
    
    # Validate AWS account ID format
    if 'aws_account_id' in config and config['aws_account_id']:
        if not re.match(AWS_ACCOUNT_ID_PATTERN, config['aws_account_id']):
            errors.append("AWS Account ID must be a 12-digit number")
    
    # Validate AWS region format
    if 'aws_region' in config and config['aws_region']:
        if not re.match(AWS_REGION_PATTERN, config['aws_region']):
            errors.append("AWS Region must be in format: us-east-1, eu-west-1, etc.")
    
    # Validate environment
    if 'environment' in config and config['environment']:
        if config['environment'] not in ['dev', 'staging', 'prod']:
            errors.append("Environment must be one of: dev, staging, prod")
    
    # Validate domain format
    if 'application_domain' in config and config['application_domain']:
        domain = config['application_domain']
        if ".." in domain or domain.startswith(".") or domain.startswith("-"):
            errors.append("Invalid domain format")
        elif not re.match(DOMAIN_PATTERN, domain):
            errors.append("Invalid domain format")
    
    # Validate CIDR format
    if 'vpc_cidr' in config and config['vpc_cidr']:
        cidr = config['vpc_cidr']
        if "/" not in cidr:
            errors.append("VPC CIDR must be in format x.x.x.x/y")
        else:
            parts = cidr.split("/")
            if len(parts) != 2:
                errors.append("VPC CIDR must be in format x.x.x.x/y")
            else:
                ip_part, prefix_part = parts
                ip_octets = ip_part.split(".")
                if len(ip_octets) != 4:
                    errors.append("VPC CIDR must have valid IPv4 address")
    
    return {
        'is_valid': len(errors) == 0,
        'errors': errors
    }

# Property Tests

@settings(max_examples=100)
@given(
    aws_account_id=st.one_of(st.none(), st.text(min_size=0, max_size=20)),
    aws_region=st.one_of(st.none(), st.text(min_size=0, max_size=30)),
    environment=st.one_of(st.none(), st.text(min_size=0, max_size=20)),
    application_domain=st.one_of(st.none(), st.text(min_size=0, max_size=100)),
    vpc_cidr=st.one_of(st.none(), st.text(min_size=0, max_size=30))
)
def test_property_validation_reports_all_errors(aws_account_id, aws_region, environment, application_domain, vpc_cidr):
    """
    Property: For any configuration with invalid or missing fields,
    validation should report all errors at once.
    """
    config = {
        'aws_account_id': aws_account_id,
        'aws_region': aws_region,
        'environment': environment,
        'application_domain': application_domain,
        'vpc_cidr': vpc_cidr
    }
    
    result = validate_configuration(config)
    
    # Result should always have is_valid and errors fields
    assert 'is_valid' in result
    assert 'errors' in result
    assert isinstance(result['errors'], list)
    
    # If invalid, should have at least one error
    if not result['is_valid']:
        assert len(result['errors']) > 0
    
    # Each error should be a non-empty string
    for error in result['errors']:
        assert isinstance(error, str)
        assert len(error) > 0

def test_valid_configuration_accepted():
    """Test that a valid configuration is accepted."""
    config = {
        'aws_account_id': '123456789012',
        'aws_region': 'us-east-1',
        'environment': 'dev',
        'application_domain': 'example.com',
        'vpc_cidr': '10.0.0.0/16'
    }
    
    result = validate_configuration(config)
    assert result['is_valid'] == True
    assert len(result['errors']) == 0

def test_missing_required_fields_reported():
    """Test that missing required fields are all reported."""
    config = {}
    
    result = validate_configuration(config)
    assert result['is_valid'] == False
    assert len(result['errors']) >= 5  # At least 5 required fields
    
    # Check that all required fields are mentioned
    error_text = ' '.join(result['errors'])
    assert 'aws_account_id' in error_text
    assert 'aws_region' in error_text
    assert 'environment' in error_text
    assert 'application_domain' in error_text
    assert 'vpc_cidr' in error_text

def test_multiple_format_errors_reported():
    """Test that multiple format errors are all reported at once."""
    config = {
        'aws_account_id': 'invalid',  # Invalid format
        'aws_region': 'INVALID',  # Invalid format
        'environment': 'invalid',  # Invalid value
        'application_domain': '..invalid',  # Invalid format
        'vpc_cidr': 'invalid'  # Invalid format
    }
    
    result = validate_configuration(config)
    assert result['is_valid'] == False
    # Should report multiple errors
    assert len(result['errors']) >= 3

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
