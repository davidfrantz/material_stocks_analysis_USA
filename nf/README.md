# Mapping of material stocks

- ``stock-mapping_var2.nf``: stock mapping script as used for USA (Frantz et al. in prep).

- run like this: 

```
export _JAVA_OPTIONS="-Xmx500G -XX:+UnlockExperimentalVMOptions -XX:+UseZGC"
cd /data/Jakku/mat_stocks/stock/USA
nextflow -Dnxf.pool.type=sync run -resume /data/Jakku/mat_stocks/git/mat_stocks/stock-mapping/type2/stock-mapping_usa.nf -w /data/Alderaan/stock -with-dag /data/Jakku/mat_stocks/stock/USA/flowchart.html -with-report /data/Jakku/mat_stocks/stock/USA/report.html
```
