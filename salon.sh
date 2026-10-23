#! /bin/bash

PSQL="psql --username=freecodecamp --dbname=salon --no-align --tuples-only --quiet --set=ON_ERROR_STOP=1"

run_sql() {
  $PSQL --command "$1"
}

print_services() {
  run_sql "SELECT service_id || ') ' || name FROM services ORDER BY service_id"
}

sql_escape() {
  printf "%s" "${1//\'/\'\'}"
}

printf "\n~~~~~ MY SALON ~~~~~\n\n"
printf "Welcome to My Salon, how can I help you?\n\n"

while true; do
  print_services
  if ! read SERVICE_ID_SELECTED; then
    exit 0
  fi

  if [[ "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ ]]; then
    SERVICE_NAME=$(run_sql "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
  else
    SERVICE_NAME=""
  fi

  if [[ -n "$SERVICE_NAME" ]]; then
    break
  fi

  printf "\nI could not find that service. What would you like today?\n"
done

printf "\nWhat's your phone number?\n"
if ! read CUSTOMER_PHONE; then
  exit 0
fi

CUSTOMER_PHONE_SQL=$(sql_escape "$CUSTOMER_PHONE")
CUSTOMER_ID=$(run_sql "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE_SQL'")

if [[ -z "$CUSTOMER_ID" ]]; then
  printf "\nI don't have a record for that phone number, what's your name?\n"
  if ! read CUSTOMER_NAME; then
    exit 0
  fi
  CUSTOMER_NAME_SQL=$(sql_escape "$CUSTOMER_NAME")
  CUSTOMER_ID=$(run_sql "INSERT INTO customers (phone, name) VALUES ('$CUSTOMER_PHONE_SQL', '$CUSTOMER_NAME_SQL') RETURNING customer_id")
  if [[ -z "$CUSTOMER_ID" ]]; then
    exit 1
  fi
else
  CUSTOMER_NAME=$(run_sql "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID")
fi

printf "\nWhat time would you like your %s, %s?\n" "$SERVICE_NAME" "$CUSTOMER_NAME"
if ! read SERVICE_TIME; then
  exit 0
fi

SERVICE_TIME_SQL=$(sql_escape "$SERVICE_TIME")
if ! run_sql "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME_SQL')" >/dev/null; then
  exit 1
fi

printf "\nI have put you down for a %s at %s, %s.\n" "$SERVICE_NAME" "$SERVICE_TIME" "$CUSTOMER_NAME"
