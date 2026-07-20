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
      throw new Error("Environment belum lengkap");
    }

    const supabase = createClient(
      supabaseUrl,
      serviceRoleKey,
    );
    const { data: order, error } = await supabase
      .from("orders")
      .select("midtrans_order_id")
      .eq("id", body.order_id)
      .single();


    if (error || !order?.midtrans_order_id) {
      throw new Error(
        "Midtrans order id tidak ditemukan"
      );
    }

    const auth = btoa(`${serverKey}:`);

    const midtransResponse = await fetch(
      `${baseUrl}/v1/payment-links/${order.midtrans_order_id}`,
      {
        method: "GET",
        headers: {
          Authorization: `Basic ${auth}`,
          Accept: "application/json",
        },
      },
    );

    const json = await midtransResponse.json();

    if (!midtransResponse.ok) {
      return new Response(
        JSON.stringify({
          success: false,
          response: json,
        }),
        {
          status: midtransResponse.status,
          headers: {
            "Content-Type": "application/json",
          },
        },
      );
    }

    const purchases = json.purchases ?? [];

    // Cari transaksi yang berhasil
    const paidPurchase = purchases.find(
      (purchase: any) =>
        purchase.payment_status === "SETTLEMENT" ||
        purchase.payment_status === "CAPTURE",
    );

    if (paidPurchase) {
      await supabase
        .from("orders")
        .update({
          order_status: "paid",
          payment_status: "paid",
        })
        .eq("id", body.order_id);

      return new Response(
        JSON.stringify({
          success: true,
          payment_status: "PAID",
          purchase: paidPurchase,
        }),
        {
          headers: {
            "Content-Type": "application/json",
          },
        },
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        payment_status: "WAITING_PAYMENT",
        purchases: purchases,
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
        message: e instanceof Error
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