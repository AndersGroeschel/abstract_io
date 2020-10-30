# Abstract IO

This Package is designed to simplify and generalize saving data. When used effectively it has the ability to treat saved data almost as you would any object.

The three basic objects in Abstract IO are AbstractIO, IOInterface, and the Translator.
- AbstractIO is the object that will be interacted with in the code, depending on what sub class and mixins are used it can do many different things, but in general it is a way for you to go straight from file or server to object.
- IOInterface provides a way for AbstractIO to communicate with the file system or whatever system is being used to save the data. For some added convienence IOInterface extends AbstractIO so the same mixins can be used on it
- The Translator translates objects from the data type they are stored as (Writable) to the data type that they are being used as in the code (Readable) and also from the readable type to the writable type.

While not all of the code is currently documented most of the older features are. I plan to do documentation for newer features as well.

## Getting Started

start by importing abstract_io.dart and extending either DirectoryIO or FileIO depending on how you plan to store and access data. Consider using the ValueFetcher, ValueStorage, or EntryStorage mixins when implementing your AbstractIO object as they most of the work for you. There are plenty of other mixins to add other functionality, such as making something listenable or giving a default value, for you to use if you want.
