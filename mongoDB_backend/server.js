import express from 'express';
import cors from 'cors';
import { MongoClient } from 'mongodb';

const app = express();
const port = process.env.PORT || 5001;

app.use(cors());
app.use(express.json());

const client = new MongoClient('mongodb+srv://ADMIN_ACCESS:BCICTWLRWDUETWHNJGB3ATBIWTAPBO1@cluster0.3qhwi.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0');

async function connectToDatabase() {
    try {
        await client.connect();
        const db = client.db('LocationsDB');
        console.log('Connected to Database');
        return { db, client };
    } catch (error) {
        console.error('Failed to connect to MongoDB:', error);
        throw new Error('Failed to connect to the database');
    }
}

async function fetchLocationData() {
    const { db } = await connectToDatabase();
  
    const washroomLocations = await db.collection('WashroomLocations').find().toArray();
    const fountainLocations = await db.collection('WaterFountainLocations').find().toArray();
  
    return { washroomLocations, fountainLocations };
}

app.get('/locations', async (req, res) => {
    try {
      const data = await fetchLocationData();
      res.json(data);
    } catch (error) {
      res.status(500).send('Error fetching data');
    }
  });

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});

// implement function to validate the returned data type to match this
const Washroom_Location = {
  _id: String,
  X: Number,
  Y: Number,
  OBJECTID: Number,
  NAME: String,
  NAME_FR: String,
  ADDRESS: String,
  ADDRESS_FR: String,
  SEASONAL: Number,
  SEASON_START: String,
  SEASON_END: String,
  HOURS_SUNDAY_OPEN: String,
  HOURS_SUNDAY_CLOSED: String,
  HOURS_MONDAY_OPEN: String,
  HOURS_MONDAY_CLOSED: String,
  HOURS_TUESDAY_OPEN: String,
  HOURS_TUESDAY_CLOSED: String,
  HOURS_WEDNESDAY_OPEN: String,
  HOURS_WEDNESDAY_CLOSED: String,
  HOURS_THURSDAY_OPEN: String,
  HOURS_THURSDAY_CLOSED: String,
  HOURS_FRIDAY_OPEN: String,
  HOURS_FRIDAY_CLOSED: String,
  HOURS_SATURDAY_OPEN: String,
  HOURS_SATURDAY_CLOSED: String,
  STAT_HOLIDAY_AVAILIBILITY: Number,
  CHANGE_STATION_CHILD: Number,
  CHANGE_STATION_ADULT: Number,
  FAMELY_TOILET: Number,
  ACCESSIBILITY: Number,
  REPORT_TELEPHONE: Number,
  SPECIAL_TOILET_TYPE: Number,
  X_COORDINATE: Number,
  Y_COORDINATE: Number,
  JURISDICTION: String
};

// Water_Fountain_Location (in JavaScript)
const Water_Fountain_Location = {
  _id: String,
  X: Number,
  Y: Number,
  OBJECTID: Number,
  BUILDING_NAME: String,
  BUILDING_NAME_FR: String,
  ADDRESS: String,
  ADDRESS_FR: String,
  GLOBALID: String,
  LAST_EDITED_DATE: String,
  OPEN_YEAR_ROUND: String,
  OPEN_YEAR_ROUND_FR: String,
  HOURS_OF_OPERATION: String,
  HOURS_OF_OPERATION_FR: String,
  INSIDE_OUTSIDE: String,
  INSIDE_OUTSIDE_FR: String,
  URL: String,
  URL_FR: String
};
