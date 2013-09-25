$(document).ready(function() {
  player_hit();
  player_stand();
  dealer_hit();
}); 

function player_hit(){
  $(document).on("click", "form#hit_form input", function(){
    $.ajax({
      type: "POST",
      url: "/game/player/hit"
    }).done(function(message) {
      $("div#game_div").replaceWith(message); 
    });

    return false;
  });  
}

function player_stand(){
  $(document).on("click", "form#stand_form input", function(){
    $.ajax({
      type: "POST",
      url: "/game/player/stand"
    }).done(function(message) {
      $("div#game_div").replaceWith(message); 
    });

    return false;
  });  
}

function dealer_hit(){
  $(document).on("click", "form#dealer_form input", function(){
    $.ajax({
      type: "POST",
      url: "/game/dealer/hit"
    }).done(function(message) {
      $("div#game_div").replaceWith(message); 
    });

    return false;
  });  
}