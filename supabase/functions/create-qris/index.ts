import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  try {
    const body = await req.json();

    const serverKey = Deno.env.get("MIDTRANS_SERVER_KEY");
    const baseUrl = Deno.env.get("MIDTRANS_BASE_URL");

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (
      !serverKey ||
      !baseUrl ||
      !supabaseUrl ||
      !serviceRoleKey
    ) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "Environment belum lengkap",
        }),
        {
          status: 500,
          headers: {
            "Content-Type": "application/json",
          },
        },
      );
    }


    const supabase = createClient(
      supabaseUrl,
      serviceRoleKey,
    );


    const auth = btoa(`${serverKey}:`);


    const midtransResponse = await fetch(
      `${baseUrl}/v1/payment-links`,
      {
        method: "POST",
        headers: {
          Authorization: `Basic ${auth}`,
          "Content-Type": "application/json",
          Accept: "application/json",
        },

        body: JSON.stringify({

          transaction_details: {
            order_id: body.order_id,
            gross_amount: body.gross_amount,
          },

          payment_type: "bank_transfer",

          bank_transfer: {
            bank: "permata",
          },

        }),
      },
    );


    const responseJson = await midtransResponse.json();


    console.log(
      "Midtrans Response:",
      responseJson,
    );


    if (!midtransResponse.ok) {
      return new Response(
        JSON.stringify({
          success: false,
          response: responseJson,
        }),
        {
          status: midtransResponse.status,
          headers: {
            "Content-Type": "application/json",
          },
        },
      );
    }


    /*
      SIMPAN ORDER ID MIDTRANS ASLI
      contoh:
      uuid-1784511080050
    */

    await supabase
      .from("orders")
      .update({
        midtrans_order_id: responseJson.order_id,
      })
      .eq(
        "id",
        body.order_id,
      );


    return new Response(
      JSON.stringify({

        success: true,

        order_id:
          responseJson.order_id,

        payment_url:
          responseJson.payment_url,

        qr_url:
          responseJson.qr_url,

      }),
      {
        headers: {
          "Content-Type": "application/json",
        },
      },
    );


  } catch (e) {

    return new Response(
      JSON.stringify({

        success: false,

        message:
          e instanceof Error
            ? e.message
            : "Unknown error",

      }),
      {
        status: 500,

        headers: {
          "Content-Type": "application/json",
        },
      },
    );

  }
});