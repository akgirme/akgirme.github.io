#!/bin/sh

if [ $# -ne 2 ]; then
    echo "\n Usage: $0 IP_ADDRESS_OF_PG_SERVER PG_PORT\n"
    exit 1
fi

v_pg_ip=$1
v_pg_port=$2
v_ip_address=$(hostname -A | cut -d' ' -f1)

echo "\n--------------------------------"
echo "My IP Address is: ${v_ip_address}"
echo "--------------------------------\n"

# Run the command and get the exit code
nc -z ${v_pg_ip} ${v_pg_port} >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "-> Checking connectivity to ${v_pg_ip}...[PASSED]"
else
    echo "-> Checking connectivity to ${v_pg_ip}...[FAILED]"
    echo "---"
    nc -zv ${v_pg_ip} ${v_pg_port}
    exit $?
fi

# Run the psql command and get the exit code
export PGPASSWORD=secret123
psql -h ${v_pg_ip} -p ${v_pg_port} -U postgres -c "select version();" >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "-> Connecting to database on ${v_pg_ip}:${v_pg_port}...[PASSED]\n"
    psql -h ${v_pg_ip} -p ${v_pg_port} -U postgres -c "select version();"
else
    echo "-> Connecting to database on ${v_pg_ip}:${v_pg_port}...[FAILED]"
    echo "---"
    psql -h ${v_pg_ip} -p ${v_pg_port} -U postgres -c "select version();"
    exit $?
fi
