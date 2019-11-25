import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router, Route, Link } from "react-router-dom";

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
        this.state = {};
    }
       render() {
        return <h1>Hello</h1>;
	}
}

let mountNode = document.getElementById("app");
ReactDOM.render(<App />, mountNode);

