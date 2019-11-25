import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Link } from "react-router-dom";
import UserTable from './UserTable.jsx';

let path = 'https://rojraman-dev.grnoc.iu.edu/oess/';
async function getUsers() {
    let url = `${path}services/admin/admin.cgi?method=get_users`;

    try {
      const resp = await fetch(url, {method: 'get', credentials: 'include'});
      const data = await resp.json();
      if (data.error_text) throw data.error_text;
      return data.results;
    } catch(error) {
      console.log('Failure occurred in get_users.');
      console.log(error);
      return [];
    }
  }

class App extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
	   users:[{
                    "email_address":"",
                    "status":"",
                    "type":"",
                    "user_id":"",
                    "family_name":"",
                    "first_name":""
                }]
	};
    }
   
    fetchUsers(props,currComponent){
	getUsers().then(function(u){
		currComponent.setState({
			users:u
		})
	});
    }   
 
    componentDidMount(props){
	this.fetchUsers(props, this);
     }

    componentDidUpdate(){
	
     }
      
       render() {
	if(this.state.users[0].user_id != ""){
		console.log(this.state.users);
		console.log(this.state.users.length);
		var users_data = [];
	
		var count = 0;
		this.state.users.forEach(function(obj){
			var data = {};
			data["First Name"] = obj.first_name;
			data["Last Name"] = obj.family_name;
			data["Username"] = obj.user_id;
			data["Email Address"] = obj.email_address;
			data["User Type"] = obj.type;
			data["User Status"] = obj.status;
			users_data[count] = data;
			count = count +1;
		});
	
		console.log(JSON.stringify(users_data));
		return <UserTable data={users_data}/>;	
            }else{
		return null;
		}
	}
}

let mountNode = document.getElementById("app");
ReactDOM.render(<App />, mountNode);

