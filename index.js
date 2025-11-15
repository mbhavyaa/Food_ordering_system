import pg from "pg"
import express from "express"
import bodyParser from "body-parser";

const app= express();
const port =3000;

app.set("view engine", "ejs");
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static("public"))

const db=new pg.Client({
    user:"postgres",
    host:"localhost",
    database: "food_order",
    password: "dpsd",
    port: 5432
});

db.connect();

let quiz=[];
db.query("select * from Restaurant",(err,res)=>{
    if(err){
        console.error("error",err.stack);
    } else{
        quiz=res.rows;
    }
    db.end();
});

app.get("/",(req,res)=>{
    res.render("index.ejs",{quiz});
})

app.listen(3000,()=>{
    console.log("server running");
})