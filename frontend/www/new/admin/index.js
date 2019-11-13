import React from "react";
import ReactDOM from "react-dom";
import "@babel/polyfill";

let path = 'https://rojraman-dev.grnoc.iu.edu/oess/';

async function getCurrentUser() {
  let url = `${path}services/user.cgi?method=get_current`;

  try {
    const resp = await fetch(url, {method: 'get', credentials: 'include'});
    const data = await resp.json();
    return data.results[0];
  } catch(error) {
    console.log('Failure occurred in getVRF.');
    console.log(error);
    return null;
  }
}

class HelloMessage extends React.Component {
  render() {
      getCurrentUser().then(function(r) {
	  console.log(r);
      });
    return <div>Hello there {this.props.name}</div>;
  }
}

var mountNode = document.getElementById("app");
ReactDOM.render(<HelloMessage name="Jane" />, mountNode);
