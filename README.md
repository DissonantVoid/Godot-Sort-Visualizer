# Sort Visualizer
A "back-to-basics" project that implements a number of sorting algorithms in gdscript
as well as adding visual effects to help see the algorithm in action!

[TODO: add gifs]

## Project Structure:
The main components are **Sorters** and **Visualizers**;
**Sorters** are scripts that contain the sorting algorithm, each script inherites
from sorter.gd and must override its virtual methods which are used to interact
with the algorithm.
**Visualizers** are scenes that take input from a sorter and translate that visually,
each visualizer must inherite from visualizer.tscn and override its virtual methods
which are used to pass and retreive information

The project is design to be highly customizable so more **Sorters** and **Visualizers** can
easily be added without having to change anything outside their implementation

The **Main** scene handles the flow of data and dependency between the components,
to start sorting a visualizer object must be added to the main scene and linked as an export variable,
while a sorter can be chosen at run-time, 

The last component in this project is the **Algorithm Picker**, which is the main ui
that is used to choose algorithms and control the method and speed of sorting

