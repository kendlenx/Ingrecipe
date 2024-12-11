The application allows us to record kitchen ingredients we have at home based on their expiration dates and get recipes based on those ingredients.
Features I’ve implemented include:
•	Creating an account and customizing our data.
•	Changing the password of the created account.
•	A page to input the kitchen ingredients we have, where we can add product names, expiration dates, quantities, and modify or delete them using +, -, and trash can buttons.
•	Sending notifications for products that are approaching their expiration dates, with options to choose when to be notified (1 day, 2 days, or 3 days before the expiry date) through the notification management screen.
•	A homepage where we receive recipes based on the ingredients we have, which can be filtered by cuisine type or diet type.
•	We can add recipes we like to favorites.
•	We can sort the recipes based on the approaching expiration date of ingredients, favorites, or the rating score.
•	When we click on a recipe, we see the preparation time, the cuisine or diet type, required ingredients, cooking instructions, a button to rate the recipe, and comments and ratings from other users. At the bottom, there are buttons to save the recipe and add it to favorites.
•	When we save a recipe, we are redirected to the screen where we can rate the recipe and leave a comment. We can also see comments made by other users.
In the next version, I plan to add features like:
•	An automatic shopping list creation screen for missing ingredients.
•	Detailed explanations of the calorie count and other properties of recipes.
•	A product addition screen where ingredients can be selected from a list instead of manually typing the names.
•	A more detailed product list screen, where we can specify measurements like kilograms, liters, etc.
•	Profile section updates to allow users to change their username, email, and upload a profile picture, in addition to just changing the password.
I rate myself at level B, as I believe my project is still very basic and simple. Many features and explanations are missing, and some of the features I plan to add should have been included in the first release.
For the database, I used Firebase to store user information, the ingredients we added, and the ratings and comments we gave to those products.
As third-party software:
•	I used the Lottie-ios package for loading animations (https://github.com/airbnb/lottie-ios).
•	I used the Firebase-ios-sdk package to store user data, products, and ratings and comments on the products. I got help from the Firebase documentation for the Firebase connection (https://github.com/firebase/firebase-ios-sdk, https://firebase.google.com/docs/ios/learn-more?hl=en#swiftui ).
•	I used the Spoonacular API to fetch recipes. I learned how to integrate this API from the Spoonacular documentation (https://spoonacular.com/food-api, https://spoonacular.com/food-api/docs).
