DATA_DIR=`pwd`/data
LOG_DIR=`pwd`/log
CONF_DIR=`pwd`/conf
IMPORT_DIR=`pwd`/import

mkdir -p "${LOG_DIR}" "${DATA_DIR}" "${CONF_DIR}" "${IMPORT_DIR}"

docker run \
	-d --name neo4j-5-3-0 \
	--publish=7474:7474 --publish=7687:7687 \
	--volume="${DATA_DIR}":/data \
	--volume="${LOG_DIR}":/logs \
	--volume="${IMPORT_DIR}":/import \
	--volume="${CONF_DIR}":/var/lib/neo4j/conf \
	neo4j:5.3.0


# visit by web browser: localhost:7474

# use generated password: 
# adios-zoom-edgar-fresh-passive-9863


