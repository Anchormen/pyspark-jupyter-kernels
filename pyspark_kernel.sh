#!/usr/bin/env bash

# THIS SCRIPT ASSUMES THAT ANACONDA IS AVAILABLE TO THE USER VIA conda
# #####################################################################
# RUN THIS SCRIPT USING THE FOLLOWING REQUIRED PARAMETERS
#
# -t | --kernels_template_path: path to pyspark_kernel.template
#           - pyspark_kernel.template is a pyhocon template used to create a jupyter kernel
#
# -d | --kernels_dir_path: root location for the kernels dir (for JUPYTER)
#           - you can use: jupyter --paths, to locate the kernels dir
#               - for directories under "data" ... $DIR_PATH/kernels is a valid kernels_dir
#           - to share this kernel with other users, consider using a shared kernels_dir
#               - accessible to the users you would like to share the kernel with
#
# -k | --kernel_name: the kernel_name
# -e | --venv_dir_path: path to the venv to be used by both the spark driver and executors
#
# --spark_home: spark home
# --spark_master: currently supporting local[*] and yarn
#
# #####################################################################
# OPTIONALLY INCLUDE ADDITIONAL SPARK CONFIGURATIONS

# --spark.*: any spark configuration parameter that can be provided to spark via PYSPARK_SUBMIT_ARGS
#           - ex. spark.driver.memory 3g and/or spark.executor.memory 4g , ...etc.
#
WORK_DIR=$(pwd)
echo WORKDIR = ${WORK_DIR}

PYSPARK_SUBMIT_ARGS=

# PARSING CLA
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -t|--kernels_template_path)
    KERNELS_TEMPLATE_PATH="$2"
    shift # past argument
    shift # past value
    ;;
    -d|--kernels_dir_path)
    KERNELS_DIR_PATH="$2"
    shift
    shift
    ;;
    -k|--kernel_name)
    KERNEL_NAME="$2"
    shift
    shift
    ;;
    -e|--venv_dir_path)
    VENV_DIR_PATH="$2"
    shift
    shift
    ;;
    --spark_home)
    SPARK_HOME="$2"
    shift
    shift
    ;;
    --spark_master)
    SPARK_MASTER="$2"
    shift
    shift
    ;;
    --spark.*)
    SPARK_CONF_KEY=${key#*--} ## removing the -- at the beginning
    PYSPARK_SUBMIT_ARGS="${PYSPARK_SUBMIT_ARGS} --conf ${SPARK_CONF_KEY}=${2}"
    shift
    shift
    ;;
    *)    # unknown option
    POSITIONAL+=("$key") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

#todo: verify all required inputs have been captured
# printing captured inputs for user's verification
echo KERNELS_TEMPLATE_PATH: ${KERNELS_TEMPLATE_PATH}
echo KERNELS_DIR_PATH: ${KERNELS_DIR_PATH}
echo KERNEL_NAME: ${KERNEL_NAME}
echo VENV_DIR_PATH: ${VENV_DIR_PATH}
echo SPARK_HOME     = ${SPARK_HOME}
echo SPARK_MASTER    = ${SPARK_MASTER}
echo SPARK_CONFIG = ${PYSPARK_SUBMIT_ARGS}
echo please verify the captured inputs, and press any key to continue or Ctr+c to exit
read -e

# creating kernel_directory
TARGET_KERNEL_DIR=${KERNELS_DIR_PATH}/${KERNEL_NAME}
rm -rf ${TARGET_KERNEL_DIR}
mkdir ${TARGET_KERNEL_DIR}
echo created kernel directory at: ${TARGET_KERNEL_DIR}


PYSPARK_SUBMIT_ARGS="--master ${SPARK_MASTER} ${PYSPARK_SUBMIT_ARGS}"
PYSPARK_DRIVER_PYTHON=${VENV_DIR_PATH}/bin/python
PYSPARK_PYTHON=${VENV_DIR_PATH}/bin/python  # assuming local deployment of spark


if [ "${SPARK_MASTER}" = 'yarn' ]; then

    # Spark on YARN
    # --------------
    # considers archiving the virtual environment and sending it to the executors
    # the driver and the executors will have ~ identical virtual environments
    # the driver is using the venv in local path provided in ${VENV_DIR_PATH}
    # each executors is using the extracted venv @ its working directory; provided via --archives ${VENV_ZIP}"#${STAGING_TAG}"
    # Note: the driver will additionally have jupyter and pyhocon packages installed (this is not required for the executors)
    # #################################################################

    # creating an archive of the venv to send to the executors
    # maintaining the archive in the kernel directory for ongoing usage
    VENV_ZIP=${TARGET_KERNEL_DIR}/pyspark_venv_${KERNEL_NAME}.zip
    rm -rf ${VENV_ZIP}
    cd ${VENV_DIR_PATH} && zip -r ${VENV_ZIP} .
    echo created virtual environment archive [for yarn] at ${VENV_ZIP}
    cd ${WORK_DIR}

    # adding --archives spark configuration and considering referencing the "extracted"
    # virtual environment from the executors working/staging directory
    STAGING_TAG=PYSPARK_VENV
    PYSPARK_SUBMIT_ARGS="${PYSPARK_SUBMIT_ARGS} --archives ${VENV_ZIP}#${STAGING_TAG}"
    PYSPARK_PYTHON=./${STAGING_TAG}/bin/python
fi


PYSPARK_SUBMIT_ARGS="${PYSPARK_SUBMIT_ARGS} pyspark-shell"
echo generated PYSPARK_SUBMIT_ARGS: ${PYSPARK_SUBMIT_ARGS}

# -------
# installing pyhocon and jupyter in the drivers virtual environment (if they do not exist)
# pyhocon is used to generate the kernel.json file from the pyspark_kernel.template
# jupyter is used to run the notebook (via ipython kernel)

source activate ${VENV_DIR_PATH}
pip install pyhocon
conda install -y jupyter


# creating the kernel.json file by applying pyhocon
export KERNEL_NAME
export SPARK_HOME
export PYSPARK_DRIVER_PYTHON
export PYSPARK_PYTHON
export PYSPARK_SUBMIT_ARGS

cat ${KERNELS_TEMPLATE_PATH} | pyhocon -f json >> ${TARGET_KERNEL_DIR}/kernel.json

source deactivate
