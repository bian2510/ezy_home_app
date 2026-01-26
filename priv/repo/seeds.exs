# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     EzyHomeApp.Repo.insert!(%EzyHomeApp.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias EzyHomeApp.Inventory

# 1. Limpiamos la casa (opcional, borra todo lo anterior)
EzyHomeApp.Repo.delete_all(EzyHomeApp.Sales.Sale)

# 2. Borramos los items de los packs
EzyHomeApp.Repo.delete_all(EzyHomeApp.Inventory.Schemas.BundleItem)

# 3. Ahora sí podemos borrar Packs y Productos sin errores
EzyHomeApp.Repo.delete_all(EzyHomeApp.Inventory.Schemas.Bundle)
EzyHomeApp.Repo.delete_all(EzyHomeApp.Inventory.Schemas.Product)
EzyHomeApp.Repo.delete_all(EzyHomeApp.Accounts.User)
EzyHomeApp.Repo.delete_all(EzyHomeApp.Accounts.Company)

company = EzyHomeApp.Repo.insert!(%EzyHomeApp.Accounts.Company{
  name: "Mi Tienda Domótica",
  tax_id: "20-12345678-9"
})

# 3. Crear Usuario vinculado a la empresa
EzyHomeApp.Repo.insert!(%EzyHomeApp.Accounts.User{
  email: "fabian@covr.care",
  hashed_password: Pbkdf2.hash_pwd_salt("password123"),
  confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second),
  company_id: company.id
})

# 2. Creamos Productos Físicos
{:ok, hub} = Inventory.create_product(%{
  name: "Hub Zigbee 3.0",
  sku: "HUB-ZIG-01",
  current_stock: 50,
  min_stock_threshold: 5,
  price: "45.00",
  company_id: company.id
})

{:ok, bombilla} = Inventory.create_product(%{
  name: "Bombilla RGB Smart",
  sku: "BULB-RGB-01",
  current_stock: 10,  # <-- ¡Poco stock!
  min_stock_threshold: 15, # Debería salir en ROJO
  price: "12.00",
  company_id: company.id
})

{:ok, _sensor} = Inventory.create_product(%{
  name: "Sensor Puerta/Ventana",
  sku: "SENS-DOOR-01",
  current_stock: 100,
  min_stock_threshold: 10,
  price: "8.50",
  company_id: company.id
})

# 3. Creamos un Pack (Bundle)
{:ok, pack} = Inventory.create_bundle(%{
  name: "Kit Iniciación Domótica",
  sku: "KIT-START-01",
  description: "Todo para empezar",
  company_id: company.id
})

# 4. Definimos la receta del Pack
# El pack lleva: 1 Hub + 2 Bombillas
Inventory.create_bundle_item(%{bundle_id: pack.id, product_id: hub.id, quantity: 1})
Inventory.create_bundle_item(%{bundle_id: pack.id, product_id: bombilla.id, quantity: 2})

IO.puts "✅ Base de datos sembrada con éxito."
