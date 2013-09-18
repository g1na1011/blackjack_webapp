require "rubygems"
require "sinatra"
require "pry"

set :sessions, true

helpers do
  def total_hand(cards)
    values = cards.map { |card| card[1] }

    total = 0
    values.each do |value|
      if value == "A"
        total += 11
      else  
        total += (value.to_i == 0 ? 10 : value.to_i) # This is for J, Q, K.
      end     
    end

    # Corrects the Ace if total is > 21.
    values.select { |value| value == "A" }.count.times do
      break if total <= 21
      total -= 10
    end

    total
  end
end

before do
  @show_hit_stand_btn = true  
  @show_dealer_hit_btn = false
end

get "/" do
  erb :home
end

get "/game" do
  # Create a deck and put it in a session.
  suits = ["S", "H", "C", "D"]
  values = ["2", "3", "4", "5", "6", "7", "8", "9","10", "J", "Q", "K", "A"]
  session[:deck] = suits.product(values).shuffle! # [["H", "8"], ["S", "3"]...]
  
  # Deal initial two cards for dealer/player.
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  if total_hand(session[:player_cards]) == 21
    @instant_bj = "BLACKJACK! YOU WIN!"
    @show_hit_stand_btn = false
  end

  erb :game
end

get "/game/dealer/hit" do
  @success = "You chose to stand."
  @show_hit_stand_btn = false
  if total_hand(session[:dealer_cards]) < 17
    @show_dealer_hit_btn = true
  end
  erb :game
end

post "/game" do
  session[:username] = params[:username]

  if session[:username].empty?
    @error = "Please submit your name."
    erb :home
  else
    redirect "/game"
  end
end

post "/game/player/hit" do 
  session[:player_cards] << session[:deck].pop
  if total_hand(session[:player_cards]) > 21
    @error = "Busted. Sorry, you lost."
    @show_hit_stand_btn = false
  end
  erb :game
end

post "/game/player/stand" do
  erb :game
  redirect "/game/dealer/hit"
end

post "/game/dealer/hit" do
  session[:dealer_cards] << session[:deck].pop
  @show_hit_stand_btn = false
  erb :game
end





