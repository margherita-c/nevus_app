# nevus.app
Nevus is an app whose purpose is to help people check and track the status of their moles. It allows to: 
- take pictures and save them on a private gallery accessible only trough the app, so that they aren't stored in public places
- identify each mole and create a history of evolution of every mole with all the pictures that Nevus has
- place the moles on a human figure, so that its location will be known even without a photo of it

## Data model
Each user has a personal folder named after the user where all the data is stored, when a user doesn't log in the account will be managed as a guest user and the data will be stored in a folder named "guest". The image data inside each user folder is organized in campaigns folders (all the photos relative to one campaign are stored into the same campaign folder).
All the data is stored into json files that are loaded and saved when entering or exiting form a screen, the json files are stored directly inside of the user folder.

/app_documents/
└── users/
    ├── guest/
    │   ├── photos.json
    │   ├── campaigns.json
    │   ├── moles.json
    │   └── campaigns/
    │       ├── campaign_001/
    │       │   ├── photo1.jpg
    │       │   └── photo2.jpg
    │       └── campaign_002/
    └── john_doe/
        ├── photos.json
        ├── campaigns.json
        ├── moles.json
        └── campaigns/
            └── campaign_001/
            
### Photo
Photos are linked to only one campaign, each image can contain more than one mole, has a list of spots identify each mole and its position. Each photo contains a description that identifies which region of the body the picture represents.
### Spot
Spots are annotations on a specific Photo that highlight moles, each spot contains info about the mole it identifies, like an ID, its position and its size. 
### Campaign
Campaigns are linked to a date and represent the group of photos taken in a specific moment (day, week) to track your moles.
### Mole
Every mole has an unique Id, a short string that describes it, a long description and 
an automatic method that retrieves all the photos where it appears.

## Screens
### auth_screen
From here you can access the app: there is a box where you need to insert your username and password and then a button to log in. If you don't have an account yet there's a "plus" button in the top right corner of the screen, frome here you'll get to another page where you can create your first account or another one.
#### add or edit an account
Here you can create your first account or add a new one, but also modify an already existing account; as a matter of fact the app lets you handle multiple accounts on the same device. Also all the data given to Nevus is strictly kept inside the app, avoiding that your private information might get released to public platforms. You can acces this page from the "plus" button in the log in screen, or from the menu, clicking "edit account". In this page you'll find a box that asks for some personal information, such as gender, age etc, but also for an username and password; at he end of the page there's a save/create button, depending on whether you are adding or modifying an acount.
### home
Here you see an image of a human figure, where in future you'll be able to place the pictures of your moles, in this way every user will be able to create an accessible map of their moles, that will surely help with the tracking. Additionaly in the homepage there are two buttons: one to access the camera and one to access the gallery, where all the photos are stored.
#### campaigns
In the homepage you can see the list of all the previous campaigns, here you can also create or import a new campaign by taking new pictures directly wih the app camera or by immporting old pictures from your phone.
### camera
On this page you can take pictures that will show up on the gallery; once you shoot a photo a message will appear saying: "Picture saved!", along with a button that will transefer you on the gallery screen. If an image can't be taken another message will apper saying: "Error taking picture".
### campaign
Here you will find all the images tha where taken, unless they where deleted; you can click on the photos to see some info, like when the picture was taken and the name of the picture. By default the images' names are all blank, but you can modify them by clicking on a button called: "Edit name".
#### single photo
here you can see soe informatione about a singular photo, like the date when the picture was taken or all the annotations. On this page you can add and edit the spots that highlight the moles.
### mole gallery
Qui ci sono tutti i nei, eventualmnte ci sarà un'immagine rappresenttiva e poche informazioni caratteristiche usate per distinguere un neo dall'altro.
### mole info
Qui c'è un focus su un singolo neo: in questa pagina si trovano tutte le informazioni e annotazioni riguardanti un solo neo.