resource "aws_secretsmanager_secret" "jwt_key" {
  name                    = "ticketflow/jwt-key"
  description             = "JWT signing key for TicketFlow services"
  recovery_window_in_days = 7

  tags = {
    Name = "ticketflow-jwt-key"
  }
}

resource "aws_secretsmanager_secret_version" "jwt_key" {
  secret_id     = aws_secretsmanager_secret.jwt_key.id
  secret_string = "changeme-replace-with-real-secret"
}

resource "aws_secretsmanager_secret" "stripe_key" {
  name                    = "ticketflow/stripe-key"
  description             = "Stripe API key for payments service"
  recovery_window_in_days = 7

  tags = {
    Name = "ticketflow-stripe-key"
  }
}

resource "aws_secretsmanager_secret_version" "stripe_key" {
  secret_id     = aws_secretsmanager_secret.stripe_key.id
  secret_string = "sk_test_changeme-replace-with-real-key"
}