# Sort Visualizer
A "back-to-basics" project that implements a number of sorting algorithms in gdscript
as well as visual effects to help see these algorithm in action!

![](https://imgur.com/pvKQpVL.gif)

![](https://imgur.com/NvqfeR8.gif)

## Contribution
Any help is greatly appreciated, and I'm very much open to suggestions and PRs.
The project uses a slightly modified version of the [godot style guide](https://docs.godotengine.org/en/3.5/tutorials/scripting/gdscript/gdscript_styleguide.html), so it's appreciated if you can stick to the original guide, but I can take care of reformating otherwise.

## Project Structure
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
it also allows both sorters and visualizers to be changed at run-time.

Interaction between **Sorters** and **Visualizers** is based on indexes, where a **Visualizer**
must provide the size of items to sort (`visualizer.get_content_count`) and a callback
function to compare between each index (`visualizer.determine_priority`). based on 
these 2 funtions a **Sorter** compares indexes and passes data back to the visualizer.
what's neat about this approach (if I do say so myself :-) ) is that a sorter doesn't have to
know the nature of data it's sorting, from a sorter point of view it just sorts indexes
based on the callback function which allow for great control over the implementation.

## 99% Progress
While I'm done with this project and have to move on to other things, this is still only 99% finished,
there is one last thing that I admittedly can't get to work even after many attempts and after bypassing
the deadline by about 2 weeks, it's `sorter_merge_sort.gd` specifically in the `next_step` function
that is supposed to do merge sorting one step at a time (see code for more info).
I might be able to implement it if I keep trying but I've already wasted a lot of time and
it's better to know when to stop and move on, maybe I'll come back to this later but for now
if any destined hero wants to go cra.. I mean try to solve this issue, I'll be in your dept for at least
2 lifetimes. and if any help is needed here's my Discord *Dissonant-Void#0235*

## Credits
Font: libre-baskerville (SIL Open Font License)

All other assets including audio and art are original and follow the same license as the project