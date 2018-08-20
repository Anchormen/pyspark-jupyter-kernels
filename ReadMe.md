# Pyspark Jupyter Kernels

A **Pyspark Jupyter Kernel**, is a [Jupyter Kernel Specification] file ```kernel.json``` that utilizes ```IPython``` and comprises not only virtual environment information but spark configuration as well. A Pyspark Jupyter Kernel ties a specific python virtual environment to a specific spark environment/configuration. The virtual environment will be used by the spark driver and executors and the spark configuration will be applied on the initialized SparkContext (ex. spark-master, executor-cores, ...etc.). 

In this repository we provide a [hocon]-based generic Pyspark Jupyter Kernel Template ```pyspark_kernels.template```, together with a bash-script ```pyspark_kernels.sh``` that takes care of the automatic generation of Pyspark Kernel specification files ```kernel.json``` based on the user input. The script convets the user inputs (ex. virtual environment path, spark configuration parameters, …etc.) to their corresponding environment variables in the template, and uses ```pyhocon``` for the generation of the kernel specification file. [Pyhocon] is a python library and for convenience it is installed in the drivers virtual environment. Additionally, the Jupyter library is installed at the driver’s virtual environment. This is necessary to use the IPython kernel. 

The script supports ```local``` and ```yarn``` spark deployments, but can be easily extended to support other cluster-managers (standalone, mesos, ...etc.). In yarn-mode, the script considers archiving the virtual environment into the created kernel directory. The generated kernel-specification file, will contain logic (the corresponding spark commands) to distribute the virtual environment archive to all executors when the kernel is starting (the spark context is being initialized). The archive is unpacked in the executors working/staging directories, and the virtual environment is useable by all the executors.

**The ```pyspark_kernels.sh``` accepts the following inputs**
  -  ```-t``` | ```--kernels_template_path```: path to pyspark_kernel.template
  - ```-d``` | ```--kernels_dir_path```: root location for the kernels dir (for JUPYTER)
    - you can use: ```jupyter --paths```, to locate the kernels dir; for directories under "data" ... ```$DIR_PATH/kernels``` is a valid kernels_dir
    - to share this kernel with other users, consider using a shared kernels_dir accessible to the users you would like to share the kernel with
  -  ```-k``` | ```--kernel_name```: the kernel_name
  -  ```-e``` | ```--venv_dir_path```: path to the venv to be used by both the spark driver and executors
  -  ```--spark_home```: spark home
  -  ```--spark_master```: currently supporting ```local[*]``` and ```yarn```
  -  ```--spark.*```: (optional) any spark configuration parameter that can be provided to spark via ```PYSPARK_SUBMIT_ARGS```
        -  ex. ```spark.driver.memory 3g``` and/or ```spark.executor.memory 4g``` , ...etc.

#### Example Usage 
```sh
$ pyspark_kernel.sh -t /usr/share/kernels_templates/pyspark_kernel.template -d /home/${USER}/.local/share/jupyter/kernels -k pyspark-pandas-yarn -e /home/${USER}/pandas-3.5 --spark_home /opt/spark --spark_master yarn --spark.executor.memory 4g --spark.executor.cores 4 --spark.driver.memory 2g
```
In the example above, the ```pyspark_kernel.sh``` expects to find the ```pyspark_kernel.template``` in the path given by ```-t```, and it will create the generated kernel file ```kernel.json``` in ```/home/${USER}/.local/share/jupyter/kernels/pyspark-pandas-yarn/kernel.json```. Since this path is local to the user, this kernel is not expected to be shared with other users (i.e. not expected to appear at other users Jupyter Noteboook Servers. The virtual environment in ```/home/${USER}/pandas-3.5``` is used by the driver, and will be zipped and distributed to the executors, when the user starts the kernel from his Jupyter Notebook Server. The archive is generated only one time, when the script is run, and wlil be persisted in ```/home/${USER}/.local/share/jupyter/kernels/pyspark-pandas-yarn/pyspark_venv_pyspark-pandas-yarn.zip```. Finally, all the spark inputs provided will be used to initilalize the SparkContext.

#### Notes
- The script assumes virtual environments are created via anaconda.
- For yarn-mode, conda virtual environments and packages **must** be created/installed using ```--copy```. This will eleimnate any hard/soft linking of packages in the virtual environment, and is essential for the executors to get a complete copy of the virtual environmnet (otherwise, broken references will exist) 
- This script assumes anaconda's binaries are available to the user (ex. $PATH)
- This script uses pip/conda for the installation of pyhocon/jupyter in the drivers virtual environment respectively. 
    - pyhocon is used to generate the kernel.json file
    - jupyter is used to run the notebook (via ipython kernel)
 - ```pyspark_kernel.template``` and ```pyspark_kernels.sh``` are kept very generic. However, in typical scenarios  ```--kernels_template_path```, ```--kernels_dir_path```, ```--spark_home```, ```--spark_master``` can be hardcoded based on the cluster being utilized. In that case the only inputs required by the user are ```--kernel_name```, ```--venv_dir_path``` and ```--spark.*```





#### Enterprise Useage & Development
The generated kernels seamlessly integrate with ```jupyterhub```. It is only required to have Jupyter's configuration aware of the user's local and shared Jupyter data directories (in which the kernels specification files live). [Jupyter have defaults to its data directories], that can be viewed using the command ```jupyter --paths```. It is also possible to add your own paths by exporting ```JUPYTER_PATH``` environment variable. [More details!]



#### More Information 
For more detailed informaiton and background knowledge, check the original blogpost [here]
If you have additional questions, please get in touch info@anchormen.nl 

License
----
APACHE 2.0

[here]: <https://anchormen.nl/blog/big-data-services/pyspark-jupyter-kernels/>
[Jupyter Kernel Specification]: <http://jupyter-client.readthedocs.io/en/stable/kernels.html>
[Pyhocon]: <https://github.com/chimpler/pyhocon>
[hocon]: <https://github.com/lightbend/config/blob/master/HOCON.md>
[Jupyter have defaults to its data directories]: <http://jupyter.readthedocs.io/en/latest/projects/jupyter-directories.html#data-files>
[More details!]: <http://jupyter.readthedocs.io/en/latest/projects/jupyter-directories.html#data-files>
