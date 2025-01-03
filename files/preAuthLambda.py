import boto3
import json


# Custom exception for handling authorization issues
class AuthorizationError(Exception):
    pass


# Main handler for the AWS Lambda function
def lambda_handler(event, context):
    # Extract the username and user pool ID from the event object
    username = event["userName"]
    user_pool_id = event["userPoolId"]

    # Logging the authentication success
    print(f"User {username} has successfully authenticated.")

    # Create a Cognito Identity Provider client
    cognito_client = boto3.client("cognito-idp", region_name="us-east-1")

    try:
        # Retrieve the user's attributes from Cognito User Pool
        response = cognito_client.admin_get_user(
            UserPoolId=user_pool_id, Username=username
        )

        # Iterate through user attributes to check for specific custom attribute
        for attribute in response["UserAttributes"]:
            # Check if we have found the custom attribute for groups
            if attribute["Name"] == "custom:groups":
                # Remove leading and trailing square brackets before splitting
                groups_string = attribute["Value"].strip("[]")
                groups = groups_string.split(',')
                # Strip whitespace around each group name to ensure clean matching
                groups = [group.strip() for group in groups]
                
                # Debugging: return groups to see if parsing is correct
                # return groups
                
                # Check if 'Amplify_Dev' is one of the groups
                if "Amplify_Dev" in groups:
                    return event  # Successfully authenticated, return the event object

        # If the required attribute is not found, raise an AuthorizationError
        raise AuthorizationError("User is not authorized to use the application.")

    # Handle the case where the user is not found in the User Pool
    except cognito_client.exceptions.UserNotFoundException:
        print(f"User {username} not found.")
        return {
            "statusCode": 404,  # HTTP Not Found
            "body": json.dumps(f"User {username} not found."),
        }
    # Handle authorization errors (such as missing attributes)
    except AuthorizationError as e:
        # Log and return the authorization failure message
        print(str(e))
        return {
            "statusCode": 403,  # HTTP Forbidden indicates lack of permission
        }
    # Handle client errors from the Cognito service
    except cognito_client.exceptions.ClientError as e:
        # Log and return the error details
        print(f"Cognito ClientError: {e}")
        return {
            "statusCode": 400,  # HTTP Bad Request
            "body": json.dumps("An error occurred with your request."),
        }
    # Handle any other unexpected issues
    except Exception as e:
        # Log and return the information about the unexpected error
        print(f"An unexpected error occurred: {e}")
        return {
            "statusCode": 500,  # HTTP Internal Server Error
            "body": json.dumps("An unexpected error occurred."),
        }
