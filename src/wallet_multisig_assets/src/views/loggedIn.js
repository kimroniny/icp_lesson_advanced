import { ActorSubclass } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import { html, render } from "lit-html";
import { renderIndex } from ".";
// import { _SERVICE } from "../../../declarations/wallet_multisig/wallet_multisig.did";

const content = () => html`<div class="container">
  <style>
    #whoami {
      border: 1px solid #1a1a1a;
      margin-bottom: 1rem;
    }
  </style>
  <h1>Internet Identity Client</h1>
  <h2>You are authenticated!</h2>
  <p>To see how a canister views you, click this button!</p>
  <input type="text" readonly id="whoami" placeholder="your Identity" />
  <div style="margin:">
      <button id="getAllProposals">获取所有提案</button>
      <button id="getAllCanisters">获取所有canisters</button>
      <button id="getAllMembers">获取小组成员名单</button>
  </div>
  <button id="logout">log out</button>
</div>`;

export const renderLoggedIn = (actor, authClient) => {
  // document.getElementById("pageContent").remove(); 
  render(content(), document.getElementById("pageContent"));

  const initFunc = async () => {
    try {
      const response = await actor.whoami();
      console.log(response);
      document.getElementById("whoami").value = response.toString();
    } catch (error) {
      console.error(error);
    }
  };
  initFunc();

  document.getElementById("logout").onclick = async () => {
    await authClient.logout();
    renderIndex();
  };

  document.querySelector("#getAllProposals").onclick = async function(e) {
    e.preventDefault();
    const button = e.target;
    button.setAttribute("disabled", true);
  
    const proposals = await actor.getAllProposals();
    var data = "";
    data += "<h1>所有的 proposals</h1><hr>"
    for (var i = 1; i < proposals.length; i++) {
      const proposal = proposals[i][0];
      data += "<h2>------------proposal of idx: " + proposal['idx'] + "------------</h2>";
      data += "<table>"
      const canister_id = proposal['canister_id'].length > 0 ? proposal['canister_id'][0].toString() : "null";
      data += "<tr>" + "<td><strong>Canister_id: </strong></td>" + "<td>"+canister_id + "</td>" + "</tr>";
      data += "<tr>" + "<td><strong>Operation: </strong></td>" + "<td>"+JSON.stringify(proposal['operation']) + "</td>" + "</tr>";
      data += "<tr>" + "<td><strong>Args: </strong></td>" + "<td>"+JSON.stringify(proposal['args']) + "</td>" + "</tr>";
      data += "</table>"
      data += "</br>"
    }
    document.getElementById("greeting").innerHTML = data;
    button.removeAttribute("disabled");
    return false;
    // document.getElementById("greeting").innerText = "\n" + JSON.stringify(proposals[1]);
  }
  
  document.querySelector("#getAllCanisters").onclick = async function(e) {
    e.preventDefault();
    const button = e.target;
    button.setAttribute("disabled", true);
  
    const canisters = await actor.getAllCanisters();
    console.log(canisters);
    var data = "";
    data += "<h1>所有的 canisters</h1><hr>"
    for (var i = 0; i < canisters.length; i++) {
      const canister = canisters[i][0];
      console.log(canister);
      data += "<h2>------------canister of idx: " + i + "------------</h2>";
      data += "<table>"
      data += "<tr>" + "<td><strong>Canister_id: </strong></td>" + "<td>"+canister['principal'].toString() + "</td>" + "</tr>";
      data += "<tr>" + "<td><strong>Status: </strong></td>" + "<td>"+Object.keys(canister['info'][0]['status'])[0] + "</td>" + "</tr>";
      data += "</table>"
      data += "</br>"
    }
    document.getElementById("greeting").innerHTML = data;
    button.removeAttribute("disabled");
    return false;
    // document.getElementById("greeting").innerText = "\n" + JSON.stringify(proposals[1]);
  }
  
  document.querySelector("#getAllMembers").onclick = async function(e) {
    e.preventDefault();
    const button = e.target;
    button.setAttribute("disabled", true);
  
    const members = await actor.getAllMembers();
    console.log(members);
    var data = "";
    data += "<h1>所有的 members</h1><hr>"
    for (var i = 0; i < members.length; i++) {
      const member = members[i];
      console.log(member);
      data += "<table>"
      data += "<tr>" + "<td><strong>principal of member(" + i + "): </strong></td>" + "<td>"+member.toString() + "</td>" + "</tr>";
      data += "</table>"
      data += "</br>"
    }
    document.getElementById("greeting").innerHTML = data;
    button.removeAttribute("disabled");
    return false;
    // document.getElementById("greeting").innerText = "\n" + JSON.stringify(proposals[1]);
  }
};
