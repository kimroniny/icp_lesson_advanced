import { wallet_multisig } from "../../declarations/wallet_multisig";

// document.querySelector("form").addEventListener("submit", async (e) => {
//   e.preventDefault();
//   const button = e.target.querySelector("button");

//   const name = document.getElementById("name").value.toString();

//   button.setAttribute("disabled", true);

//   // Interact with foo actor, calling the greet method
//   const greeting = await wallet_multisig.greet(name);

//   button.removeAttribute("disabled");

//   document.getElementById("greeting").innerText = greeting;

//   return false;
// });

// document.querySelector("#getAllProposals").addEventListener("onclick", async (e) => {
//   e.preventDefault();
//   const proposals = await wallet_multisig.getAllProposals();
//   document.getElementById("greeting").innerText = proposals;

//   return false;
// });

document.querySelector("#getAllProposals").onclick = async function(e) {
  e.preventDefault();
  const button = e.target;
  button.setAttribute("disabled", true);

  const proposals = await wallet_multisig.getAllProposals();
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

  const canisters = await wallet_multisig.getAllCanisters();
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

  const members = await wallet_multisig.getAllMembers();
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

// getAllProposals = async () => {
//   const proposals = await wallet_multisig.getAllProposals();
//   document.getElementById("greeting").innerText = proposals;
// }

// getAllCanisters = async () => {
//   const canisters = await wallet_multisig.getAllCanisters();
//   document.getElementById("greeting").innerText = canisters;
// }

// getAllMembers = async () => {
//   const members = await wallet_multisig.getAllMembers();
//   document.getElementById("greeting").innerText = members;
// }

// function getAllCanisters() {
//   const canisters = await wallet_multisig.getAllCanisters();
//   document.getElementById("greeting").innerText = canisters;
// }

// function getAllMembers() {
//   const members = await wallet_multisig.getAllMembers();
//   document.getElementById("greeting").innerText = members;
// }