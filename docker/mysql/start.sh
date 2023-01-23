DATA_DIR=/data/soft/mysql/data
LOG_DIR=/data/soft/mysql/log
CONF_DIR=/data/soft/mysql/conf

mkdir -p "$DATA_DIR" "$LOG_DIR" "$CONF_DIR"
mkdir -p "${CONF_DIR}/conf.d"
mkdir -p "${CONF_DIR}/mysql.conf.d"


docker run -p 3366:3306 --name mysql-5-7 --restart=always -d \
        -v ${LOG_DIR}:/var/log/mysql \
        -v ${DATA_DIR}:/var/lib/mysql \
        -v ${CONF_DIR}:/etc/mysql \
        -e MYSQL_ROOT_PASSWORD=123456 \
        mysql:5.7
