# Google Analytics Dashboard

![screenshot](https://cloud.githubusercontent.com/assets/80459/7712656/31a38222-fe38-11e4-998b-8d5d9a5c6956.png)

This is a [Dashing](http://shopify.github.io/dashing) project that has been customized to add a Google Analytics view. It also has some other visual tweaks to bring Dashing up to speed.

This project is heavily based on the work [@mtowers](https://github.com/mtowers) did for [his visitor count widget](https://gist.github.com/mtowers/5986576).

### Features

- Configurable to show relevant goals that are set up in Google Analytics
- Single-color (black) for all Dashboard widgets (This can be customized in the Widget SCSS)
- Already set up to go on a wide-screen television
- Configured with [Sinatra Cyclist](https://github.com/vrish88/sinatra_cyclist) to rotate through multiple dashboards
- Uses the latest FontAwesome icons from the CDN
- Fixes an annoying icon positioning issue on most default Dashing installs

### Set Up Instructions

This project has three environment variables you must set. 

- `GOOGLE_SERVICE_ACCOUNT_EMAIL`
- `GOOGLE_PRIVATE_KEY`
- `GOOGLE_PRIVATE_KEY_SECRET`
- `GOOGLE_ANALYTICS_VIEW_ID`

Obtaining them can be a bit of a chore, particularly if you want to deploy to Heroku and are setting up the project so that *no private credentials are exposed on GitHub*. Be careful with this one.

These instructions are lifted almost entirely from the original widget.

#### 1. Create and download a new private key for Google API access

1.  Go to https://code.google.com/apis/console
2.  Click 'Create Project'
3.  Enable 'Analytics API' service and accept both Terms of Services
4.  Click 'API Access' in the left-hand navigation menu
5.  Click 'Create an OAuth 2.0 Client ID'
6.  Enter a product name (e.g. 'Dashing Widget') - logo and url are optional
7.  Click 'Next'
8.  Under Application Type, select 'Service Account' (Important step -- other account types will not work.)
9.  Click 'Create Client ID'
10.  Click 'Download private key' _NOTE: This will be your only opportunity to download this key._
11.  Note the password for your new private key, usually 'notasecret'. This will be the value for `GOOGLE_PRIVATE_KEY_SECRET`
12.  Close the download key dialog
13.  Find the details for the service account you just created and copy it's email address which will look something like this: `210987654321-3rmagherd99kitt3h5@developer.gserviceaccount.com`. This will be the value for `GOOGLE_SERVICE_ACCOUNT_EMAIL`

#### 2. Attach your Google API service account to your Google Analytics profile

_Note: you will need to be an administrator of the Google Analytics profile_

1. Log in to your Google Analytics account: http://www.google.com/analytics/
2. Click 'Admin' in the upper-right corner
3. Select the account containing the profile you wish to use
4. Select the property containing the profile you wish to use
5. Select the profile you wish to use
6. Click the 'Users' tab
7. Click '+ New User'
8. Enter the email address you copied from step 13 above
9. Click 'Add User'

#### 3. Locate the ID for your Google Analytics data view

1. On your Google Analytics Admin section, click the 'View Settings' panel (Such as "All Data")
2. Copy your View ID  (e.g. 654321). This is the value for `GOOGLE_ANALYTICS_VIEW_ID`.

#### 4. Convert your Certificate to an ASCII string

This is a variation from the original widget, and it is mainly so you do not store the certificate with the repository (and put it in an environment variable with other configuration credentials.) From the command line, run this to unlock the certificate.

```bash
$ openssl pkcs12 -info -nodes -in YourApp-a0b2c2d3456.p12 > output.txt
```

When prompted for the password, it should be `notasecret`.

The contents of `output.txt` can now be stored as the value for `GOOGLE_PRIVATE_KEY`.

1. Open the file in a text editor
2. Replace every line break with a `\n` so that it all fits on one line
3. Put quote marks around it.
4. In Heroku or other configuration management (locally, `.env`), set this string as the value of `GOOGLE_PRIVATE_KEY` (e.g. `export GOOGLE_PRIVATE_KEY="Bag Attributes\n    friendlyName: privatekey\n    localKeyID:...`)

## Starting the Dashboard

You should be ready to run the Dashing dashboard as usual:

```
$ dashing start
```

Navigate to http://0.0.0.0:3030/_cycle to see everything in action.
