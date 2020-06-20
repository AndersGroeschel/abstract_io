# Abstract IO

This Package is designed to simplify and generalize saving data. Because Abstract IO
is meant to generalize saving data both localy and externaly no specific implementation is
provided in this package. As of the time I'm writting this local file storage and
storage for firebase has been implemented.

The very base of this package is the Abstract_IO object, which takes a Translator and 
an IOInterface. 
The translator translates the data from it's saved type into whatever type you decide, 
this often will have to be implemented by you. 
The IOInterface provides a way for Abstract_IO to send and recieve data from wherever 
it is stored, some IOInterfaces have been implenented in seperate packages and you are 
free to create your own

For more in depth information look at the documention. At the time of writing documentation is complete.

## Getting Started

start by importing abstract_io.dart and extending Abstract_IO, consider using either the 
ValueStorage mixin or the ValueFetcher mixin both of which complete the functionality of Abstract_IO
