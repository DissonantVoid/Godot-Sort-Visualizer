# Sort Visualizer
A "back-to-basics" project that implements a number of sorting algorithms in gdscript
as well as visual effects to help see the algorithm in action!

[TODO: add gifs]

## Project Structure:
The main components are **Sorters** and **Visualizers**;
**Sorters** are scripts that contain the sorting algorithm, each script inherites
from `sorter.gd` and must override its virtual methods which are used to interact
with the algorithm.
**Visualizers** are scenes that take input from a sorter and translate that visually,
each visualizer must inherite from `visualizer.tscn` and override its virtual methods
which are used to pass and retreive information

The project is designed to be highly customizable so more **Sorters** and **Visualizers** can
easily be added without having to change anything outside their implementation

The **Main** scene handles the flow of data and dependency between each component,
to start sorting a visualizer object must be added to the main scene and linked as an export variable,
while a sorter can be chosen at run-time,

The last main component in this project is the **Algorithm Picker**, which is the ui
that is used to choose algorithms and control the method and speed of sorting

Interaction between **Sorters** and **Visualizers** is based on indexes, where a **Visualizer**
must provide the size of items to sort (`visualizer.get_content_count()`) and a callback
function to compare between each index (`visualizer.determine_priority()`). based on 
these 2 funtions a **Sorter** compares indexes and passes data back to the visualizer
(`visualizer.update_indexes()` or `visualizer.update_all()`). what's neat about this
approach is that a sorter doesn't have to know the nature of data it's sorting, from a
sorter point of view it just sorts indexes based on the callback function which allow for
great control over the visualizer implementation (if I do say so myself :-) ).

