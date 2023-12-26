"use strict"

const deletePubsModal = document.getElementById('delete-publications-modal')
deletePubsModal.addEventListener('show.bs.modal', event => {
  // Button that triggered the modal
  const button = event.relatedTarget
  const pubDate = button.getAttribute('data-bs-date')
  const modalTitle = deletePubsModal.querySelector('.modal-title')
  modalTitle.textContent = "Delete Publication from " + pubDate

  const deleteOnedayButton = document.getElementById('delete-one-day')
  deleteOnedayButton.value = pubDate

  const deleteManyDaysButton = document.getElementById('delete-many-days')
  deleteManyDaysButton.value = pubDate
})
