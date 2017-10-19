class CartController < ApplicationController
  def add_to_cart
    @order = current_order

    if params[:quantity].blank?
      flash[:error] = "Select Quantity for your order"
      redirect_to root_url
    else
      line_item = @order.line_items.new(product_id: params[:product_id], quantity: params[:quantity])
      @order.save
      session[:order_id] = @order_id

  	 
  	 line_item.update(line_item_total: (line_item.quantity * line_item.product.price))

  	 redirect_to root_url 
    end 
  	# line_item = LineItem.new
  	# line_item.product_id = params[:product_id]
  	# line_item.quantity = params[:quantity]
  	# line_item.line_item_total = line_item.product.price * line_item.quantity
  	# line_item.save

  	# redirect_to root_url
  end

  def view_order
  end

  def checkout
  	line_item = current_order.line_items

    if line_item.empty?

      redirect_to root_url
    else
          @order = current_order
        	@order.update(user_id: current_user.id, subtotal: 0)

        	line_items.each do |line_item|
        		line_item.product.update(quantity: (line_item.product.quantity - line_item.quantity))

        		if @order.order_items[line_item.product_id].nil?
        			@order.order_items[line_item.product_id] = line_item.quantity
        		else
        			@order.order_items[line_item.product_id] += line_item.quantity
        		end 

        		@order.subtotal += line_item.line_item_total
        	end

        	@order.save

        	@order.update(sales_tax: (@order.subtotal * 0.08))

        	@order.update(grand_total: (@order.subtotal + @order.sales_tax))

        	
    end 

  end

  def cancel_checkout
    order = Order.find(params[:order_id])
    session.delete(order_id)
    order.destroy

    redirect_to root_url

  end

  def order_complete
   # Amount in cents

      line_items = current_order.line_items
      @order = Order.find(params[:order_id])
      @amount = 500

      customer = Stripe::Customer.create(
        :email => params[:stripeEmail],
        :source  => params[:stripeToken]
      )

      charge = Stripe::Charge.create(
        :customer    => customer.id,
        :amount      => @amount,
        :description => 'Rails Stripe customer',
        :currency    => 'usd'
      )

      session.delete(:order_id)
      line_items.destroy_all

    rescue Stripe::CardError => e
      flash[:error] = e.message
      redirect_to new_charge_path
      end 


  

end
