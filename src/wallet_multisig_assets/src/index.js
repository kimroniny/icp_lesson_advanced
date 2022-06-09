import { wallet_multisig } from "../../declarations/wallet_multisig";

document.querySelector("form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const button = e.target.querySelector("button");

  const name = document.getElementById("name").value.toString();

  button.setAttribute("disabled", true);

  // Interact with foo actor, calling the greet method
  const greeting = await wallet_multisig.greet(name);

  button.removeAttribute("disabled");

  document.getElementById("greeting").innerText = greeting;

  return false;
});

getAllProposals = async () => {
  const proposals = await wallet_multisig.getAllProposals();
  document.getElementById("greeting").innerText = proposals;
}

// function getAllCanisters() {
//   const canisters = await wallet_multisig.getAllCanisters();
//   document.getElementById("greeting").innerText = canisters;
// }

// function getAllMembers() {
//   const members = await wallet_multisig.getAllMembers();
//   document.getElementById("greeting").innerText = members;
// }