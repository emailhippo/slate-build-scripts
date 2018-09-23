#!/bin/bash -
#title			:init-slate.sh
#description	:This script processes a swaggerhub swagger.json definition and formats it to a document that can be used as a quick-start for slate docs.
#author			:Rowland O'Connor @ Email Hippo
#date			:20180920
#usage			:./init-slate.sh -k {SwaggerHub API Key} -u {Swagger URL} -o {The output folder to send index.html.md and logo.png to}
#=====================================================================================================================================

# Error options
#exec 3>&1 4>&2
#trap 'exec 2>&4 1>&3' 0 1 2 3
#exec 1>log.out 2>&1
set -e # halt on any error

# -- Global variables

# RO / Constants
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
TMP_FILE=/tmp/api.json
TMP_INDEX_MD_FILE=/tmp/index.html.md
OPTS_FILE=$CURRENT_DIR/opts.json

# Assigned from run params
while getopts k:u:o: option
do
case "${option}"
in
k) API_KEY=${OPTARG};;
u) SWAGGER_URL=${OPTARG};;
o) OUTPUT_FOLDER=${OPTARG};;
esac
done
# --

# Initialize the working folders etc
init(){
	rm -rf $OUTPUT_FOLDER
	mkdir $OUTPUT_FOLDER
}

# Download the swagger definition
download_wadl(){
	api_key=$1
	swagger_url=$2
	curl -H "accept: application/json" -H Authorization:$1 $2?pretty=true>$TMP_FILE
	return 0	
}

# Process downloaded file and generate markdown
process(){
	widdershins --environment $OPTS_FILE $TMP_FILE -o $TMP_INDEX_MD_FILE markdown

	return 0
}

# Publishes / outputs the files
publish(){
	cp -f $TMP_INDEX_MD_FILE $OUTPUT_FOLDER/index.html.md
}

# Main entry point
main(){
	echo The API key is $API_KEY
	echo The swagger URL is $SWAGGER_URL
	

	#set up the local environment
	init

	download_wadl $API_KEY $SWAGGER_URL
	echo downloaded Swagger schema from $SWAGGER_URL

	process
	echo transformed $SWAGGER_URL to $TMP_INDEX_MD_FILE

	publish
	echo published files to $OUTPUT_FOLDER

	return 0
}

# Execute
main

