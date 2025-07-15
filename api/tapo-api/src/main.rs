use std::env;
use num::clamp;
use tapo::ApiClient;

#[tokio::main]
async fn main() {
    let args: Vec<String> = env::args().collect();

    let username: String = args.get(1).unwrap().to_string();
    let password: String = args.get(2).unwrap().to_string();
    let ip: String = args.get(3).unwrap().to_string();
    let action: String = args.get(4).unwrap().to_string();

    let device = ApiClient::new(username, password)
        .l530(ip)
        .await.unwrap();
    match action.as_str() {
        "brightness" => {
            let value = match args.get(5) {
                Some(value) => value,
                None => "-1"
            };
            let value_int = clamp(value.parse::<u8>().unwrap_or_else(|_| 0),0,100);

            if value_int > 0 {
                device.set_brightness(value_int).await.expect("Brightness out of bounds");
            }
            let dev_state = device.get_device_info().await.unwrap();
            println!("{{\"enabled\":{},\"color\":{},\"brightness\":{}}}", dev_state.device_on,dev_state.color_temp,dev_state.brightness);
        },
        "temperature" => {
            let value = match args.get(5) {
                Some(value) => value,
                None => "-1"
            };
            let value_int = clamp(value.parse::<u16>().unwrap_or_else(|_| 0),2500,6500);

            if value_int > 0 {
                device.set_color_temperature(value_int).await.expect("Color out of bounds");
            }
            let dev_state = device.get_device_info().await.unwrap();
            println!("{{\"enabled\":{},\"color\":{},\"brightness\":{}}}", dev_state.device_on,dev_state.color_temp,dev_state.brightness);
        },
        "on" => match device.on().await {
            Ok(_) => {
                let dev_state = device.get_device_info().await.unwrap();
                println!("{{\"enabled\":{},\"color\":{},\"brightness\":{}}}", dev_state.device_on,dev_state.color_temp,dev_state.brightness);
            },
            Err(_) => {
                println!("Error")
            }
        },
        "off" => match device.off().await {
            Ok(_) => {
                let dev_state = device.get_device_info().await.unwrap();
                println!("{{\"enabled\":{},\"color\":{},\"brightness\":{}}}", dev_state.device_on,dev_state.color_temp,dev_state.brightness);
            },
            Err(_) => {
                println!("Error")
            }
        },
        "toggle" => match device.get_device_info().await.unwrap().device_on {
            true => if let Ok(_) = device.off().await {
                let dev_state = device.get_device_info().await.unwrap();
                println!("{{\"enabled\":{},\"color\":{},\"brightness\":{}}}", dev_state.device_on, dev_state.color_temp, dev_state.brightness);
            } else {
                println!("Error")
            },
            false => if let Ok(_) = device.on().await {
                let dev_state = device.get_device_info().await.unwrap();
                println!("{{\"enabled\":{},\"color\":{},\"brightness\":{}}}", dev_state.device_on, dev_state.color_temp, dev_state.brightness);
            } else {
                println!("Error")
            },
        },
        "state" => {
            let dev_state = device.get_device_info().await.unwrap();
            println!("{{\"enabled\":{},\"color\":{},\"brightness\":{}}}", dev_state.device_on,dev_state.color_temp,dev_state.brightness);
        },
        _ => println!("Action not implemented"),
    }
}
