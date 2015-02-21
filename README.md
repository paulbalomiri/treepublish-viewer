# treepublish-viewer
package and default app for visualizing treepublish workings

This Package helps you create meaningful publish functions using the 
[`pba:treepublish`](https://github.com/paulbalomiri/treepublish) package.

It allows for the creation of collection schemas with links and analysing the 
tree expansion through those links within the given model

Terms:
* **publish stack** : A stack of publish functions, each publishing content to the next one, 
 while allowing for transformations on the published objects to become pluggable. [TODO: add graphic]
* **tree publishing** the publishing of the *transitive closure* of linked objects
* **published set/transitive closure** The set of documents in which no one document points to another which is 
not in the same set see [wikipedia](http://en.wikipedia.org/wiki/Transitive_closure)
* **link definition** A definition for a link, as opposed to a link instance. The definition can be simply `true`
 meaning that the field is a link.
* **link** 

##What is
* Display of schemas
* Generation of random schemas. This mainly helps for testing `pba:treeview`, but is also helpful for generating code
code examples to ease up/make understandable the creation procedure for schemas with links
* Designed schemas can be downloaded into packages containing the schema definition.
* The publish

##What will be
* Editor tweaks
  * modify generated files (and prevent further generation)
  * Augment generated files (especially package.js)
* visualize the publish stack
* edge/link transformation of pubished documents 
  * a dependent document aquires additional properties when accessed through a link
  * e.g. `John` (contact) -`link`-> `Wilkinson Street` (adress) . 
    * 'Home' would be a role of the address for one specific contact.)
    * in the database you would have a `home` field on the contact document containing link to `Wilkinson Street` 
    * in the Blaze renderer you would want `home` to render as  a house icon next to `Wilkinson Street`
    * upon change (say `home`-> `safehouse`) you would like to render a mask, thus invalidationg the *Address* template, not the *contact* template
    * **TODO: think of a better example** PR accepted :)
    
##What might be
* formalization of the *publish stack*
  * proper partitioning of data into link/link properties
  * multiple link resolution models 
  * Splitting the publish functions into a into source/sink model
* fast c++/boost implementation of reachability graph for links
* linking to other stuff than mongo documents (urls?)
* asynchroneous link resolution (e.g. )
