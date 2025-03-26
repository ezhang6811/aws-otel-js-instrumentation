for i in {1..100}; do
  echo "Iteration $i: Updating environment variables to simulate cold start"

  # Update environment variables
  aws lambda update-function-configuration \
    --function-name aws-opentelemetry-distro-nodejs \
    --environment '{"Variables":{"AWS_LAMBDA_EXEC_WRAPPER":"/opt/otel-instrument","FOO":"BAR_'$i'"}}' > /dev/null

  # Wait a short time for changes to take effect
  sleep 5

  # Invoke the Lambda function
  echo "Iteration $i: Invoking Lambda function"
  aws lambda invoke --function-name aws-opentelemetry-distro-nodejs --payload '{}' response.json > /dev/null

  # Wait to simulate cold start reset
  echo "Iteration $i: Waiting for cold start reset"
  sleep 5
done