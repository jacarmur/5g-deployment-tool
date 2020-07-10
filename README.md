# Urban 5GRX
An automated 5G deployment tool written in Matlab

## Starting 🚀


### Requirements 📋

 - Although this  tool is written in Matlab, it needs another Python application to run. Its name is Open Street Map Building Parser and you can find it here: https://github.com/FranciscoQuero/open_street_maps_buildings_parser .

 - Matlab R2019b or higher is required to run this app.
 - Python 3 is required to run the buildings parser.

### Setting it up 🔧

 - Unzip both Urban 5GRX and Open Street Map building parser into the same directory
 - Install Pyhton requirements:

```
pip install -r requirements.txt
```

## Run it! ⚙️

Open Matlab and go to the directory where both apps are located.

In Matlab command line, write:


```
main
```

You will see the UI. Just modify the parameters you want and click on "START!"



## Built with 🛠️

* [Matlab](https://www.mathworks.com/products/matlab.html) - The main language
* [Python 3](https://www.python.org/downloads/) - The aux langauge
* [Open Street Map API](https://wiki.openstreetmap.org/wiki/API_v0.6) - We used this API to retrieve the 3D buildings models
* [Open Cell ID API](http://wiki.opencellid.org/wiki/Main_Page) - We used this API to retrieve the cells location

## Contribute 🖇️
Please, feel free to open any issue, Pull Request or to just fork this project.

## Author ✒️

* **Francisco J. Quero** - [FranciscoQuero](https://github.com/FranciscoQuero)

## License 📄

This project has been created under the GNU LGPL 3.0 license - see [LICENSE.md](LICENSE.md) for more details

