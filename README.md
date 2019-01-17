# oir2stdData
MATLAB script for converting Olympus .oir image files into MATLAB readable images and metadata. <br>
These scripts were tested at MATLAB 2018a for Windows and Linux
## usage
Default usage <br>
```
[~,stdData]=oir2stdData(pathToFile); 
```
pathToFile: string for file location. <br>
 stdData is struct containing images and metadata <br>
 stdData.Image: cell array: each cell contains xyzt movie <br>
 stdData.Metadata: struct contains metadata of movie(s) <br>
 *caution: Opening files can need huge memory. <br>

if you want to save data as a series of small files (<1GB), use,  <br>
```
output_list=oir2stdData(pathToFile,0,0);
```

## trouble shoot
if an error occurred, try,<br>
```
[~,stdData]=oir2stdData(pathToFile,1,1); <br>
```
or
```
output_list=oir2stdData(pathToFile,0,1); 
```
Setting the last flag as 1 make opening speed bit slower but sometimes resolve errors.
