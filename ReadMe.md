# Pyspark Jupyter Kernels 

This repository acts as a resulting artifact to the blogpost published [here]. It contains a generic PysparkJupyterKernel template ```pyspark_kernels.templates``` and a generic bash automation script ```pyspark_kernels.sh``` that together automates the creation of custom, user-defined **Pyspark Jupyter Kernels**.

The ```pyspark_kernels.sh``` accepts the following inputs 
  -  ```-t``` | ```--kernels_template_path```: path to pyspark_kernel.template
        - pyspark_kernel.template is a pyhocon template used to create a pyspark jupyter kernel
  - ```-d``` | ```--kernels_dir_path```: root location for the kernels dir (for JUPYTER)
    - you can use: ```jupyter --paths```, to locate the kernels dir
    - for directories under "data" ... ```$DIR_PATH/kernels``` is a valid kernels_dir
    - to share this kernel with other users, consider using a shared kernels_dir accessible to the users you would like to share the kernel with
  -  ```-k``` | ```--kernel_name```: the kernel_name
  -  ```-e``` | ```--venv_dir_path```: path to the venv to be used by both the spark driver and executors
  -  ```--spark_home```: spark home
  -  ```--spark_master```: currently supporting ```local[*]``` and ```yarn```
  -  ```--spark.*```: (optional) any spark configuration parameter that can be provided to spark via ```PYSPARK_SUBMIT_ARGS```
        -  ex. ```spark.driver.memory 3g``` and/or ```spark.executor.memory 4g``` , ...etc.

**note:** 
- This script assumes anaconda is available to the user via ```conda```
- This script will additionally install jupyter and pyhocon libraries to the drivers virtual envionment. 
    - pyhocon is used to generate the kernel.json file
    - jupyter is used to run the notebook (via ipython kernel)



#### Example Usage 


```sh
$ pyspark_kernel.sh -t /usr/share/kernels_templates/pyspark_kernel.template -d /home/${USER}/.local/share/jupyter/kernels -k pyspark-pandas-yarn -e /home/${USER}/pandas-3.5 --spark_home /opt/spark --spark_master yarn --spark.executor.memory 4g --spark.executor.cores 4 --spark.driver.memory 2g
```
In the example above, the ```pyspark_kernel.sh``` expects to find the ```pyspark_kernel.template``` in the path given by ```-t```, and it will create the generated kernel file ```kernel.json``` in ```/home/${USER}/.local/share/jupyter/kernels/pyspark-pandas-yarn/kernel.json```. Since this path is local to the user, this kernel is not expected to be shared with other users (i.e. not expected to appear at other users Jupyter Noteboook Servers. The virtual environment in ```/home/${USER}/pandas-3.5``` is used by the driver, and will be zipped and distributed to the executors, when the user opens the kernel from his Jupyter Notebook Server. Finally, all the spark inputs provided will be used to initilalize the SparkContext. 


[here]: <http://todo-link-to-blog-post>

License
----
APACHE 2.0

