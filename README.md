RZCollectionList
================
A framework for transforming and combining data from Core Data and other sources and displaying it in a UITableView or UICollectionView.

## Collection Lists
### Basic Lists
#### RZArrayCollectionList
A basic list that provides sectioning for an array of objects. It also allows mutation of the sections and objects.

#### RZFetchedCollectionList
A basic list that wraps an NSFetchedResultsController and implements the NSFetchedResultsControllerDelegate protocol, passing along the content change notifications to the collection list observers.

### Transformable Lists
#### RZFilteredCollectionList
A transformable list that filters a source list using an NSPredicate.

#### RZSortedCollectionList
A transformable list that sorts a source list using an array of NSSortDescriptors.

#### RZCompositeCollectionList
A transformable list that combines an array of source lists into a single collection list.

## Collection List Data Sources
#### RZCollectionListTableViewDataSource
A data source object that takes an RZCollectionList and makes it the data source of a UITableView.

#### RZCollectionListCollectionViewDataSource (TODO)
A data source object that takes an RZCollectionList and makes it the data source of a UICollectionView.

## Examples
Check out the Demo Project in RZCollectionList-Demo for examples of how to use each type of collection list.

## License
RZCollectionList is distributed under an [MIT License](http://opensource.org/licenses/MIT). See the LICENSE file for more details.