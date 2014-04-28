Name         = 'Book2Price';
Desc         = 'Book value per share divided by price per share';
Class        = 'Book2Price';
isHighBetter = 1;
isActive     = 1;
isProd       = 0;
 
factorId = Factory.Register2DB(Name, Desc, Class, isHighBetter, isActive, isProd);
