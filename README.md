# Sort Visualizer
A "back-to-basics" project that implements a number of sorting algorithms in gdscript
as well as visual effects to help see these algorithm in action!

![](https://imgur.com/qjLrCSn.gif)

![](https://imgur.com/BP7AsK8.gif)

## Contribution
Any help is greatly appreciated, and I'm very much open to suggestions and PRs.
code optimizations are also needed at the moment and any contributions in that regard would help speed up the process.
The project uses a slightly modified version of the [godot style guide](https://docs.godotengine.org/en/3.5/tutorials/scripting/gdscript/gdscript_styleguide.html), so it's highly appreciated if you can stick to the original guide, but I can take care of reformating otherwise.

## Project Structure:
The main components are **Sorters** and **Visualizers**,
**Sorters** are scripts that contain the sorting algorithm, each script inherites
from `sorter.gd` and must override its virtual methods to interact with the algorithm.
**Visualizers** are scenes that take input from a sorter and translate that visually overtime,
each visualizer must inherite from `visualizer.tscn` and override its virtual methods
to retreive information.

The project is designed to be highly customizable so more **Sorters** and **Visualizers** can
easily be added without having to change anything outside their implementation.

The **Main** scene handles the flow of data and dependency between components,

The last main component in this project is the **Main Interface**, which is the UI
that is used to control sorting algorithms as well as the method and speed of sorting etc.
is also allows both sorters and visualizers to be changed at run-time.

Interaction between **Sorters** and **Visualizers** is based on indexes, where a **Visualizer**
must provide the size of items to sort (`visualizer.get_content_count`) and a callback
function to compare between each index (`visualizer.determine_priority`). based on 
these 2 funtions a **Sorter** compares indexes and passes data back to the visualizer.
what's neat about this approach (if I do say so myself :-) ) is that a sorter doesn't have to know the nature of data it's sorting, from a sorter point of view it just sorts indexes based on the callback function
which allow for great control over the implementation.

