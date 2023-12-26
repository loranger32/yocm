"use strict"

const userEmail = document.querySelector('#user_email').textContent;
const deleteUserButton = document.querySelector("#delete_user_button");
deleteUserButton.addEventListener('click', confirmDeleteUser);

const deleteZipCodeButton = document.querySelector("#delete_zip_button");
deleteZipCodeButton.addEventListener('click', confirmDeleteZipCode);

const deleteEnterpriseButton = document.querySelector("#delete_enterprise_button");
deleteEnterpriseButton.addEventListener('click', confirmDeleteEnterprise);

function confirmDeleteUser(e) {
  let confirmation = prompt('This is a definitive action ! Please type in the email address of user to go on.');
  if (confirmation != userEmail) {
    e.preventDefault();
    alert("Input doesn't match user email. Operation cancelled.");
    return;
  }
}

function confirmDeleteZipCode(e) {
  if (!confirm("Confirm deletion of zip code ?")) {
    e.preventDefault();
    return;
  }
}

function confirmDeleteEnterprise(e) {
  if (!confirm("Confirm deletion of enterprise ?")) {
    e.preventDefault();
    return;
  }
}
