Kal
===

A branch of the Kal Dictionary control updated with the iOS 7 layout

<img src="https://cloud.githubusercontent.com/assets/3181568/5018279/0fccd656-6a83-11e4-8034-e45445e27722.png" width="300px"/>

###Usage:

1.  Build the project
2.  Add the Kal.framework and Kal.Bundle files into your existing project.

Note: All of the following example code assumes that it is being called from
within another UIViewController which is in a UINavigationController hierarchy.

How to display a very basic calendar (without any events):

    KalViewController *calendar = [[[KalViewController alloc] init] autorelease];
    [self.navigationController pushViewController:calendar animated:YES];

In most cases you will have some custom data that you want to attach
to the dates on the calendar. The first thing you must do is provide
an implementation of the KalDataSource protocol. Then all you need to do
to display your annotated calendar is instantiate the KalViewController
and tell it to use your KalDataSource implementation (in this case, "MyKalDataSource"):

    id<KalDataSource> source = [[MyKalDataSource alloc] init];
    KalViewController *calendar = [[[KalViewController alloc] initWithDataSource:source] autorelease];
    [self.navigationController pushViewController:calendar animated:YES];

NOTE: KalViewController does not retain its datasource. You probably will want to store a reference to the dataSource in an instance variable so that you can release it after the calendar has been destroyed.
