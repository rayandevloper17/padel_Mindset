#!/usr/bin/env python3
#             self.headers['eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJyb3VtaXNzYW1vdWFsaWRAZ21haWwuY29tIiwianRpIjoiZGQxYzZlZjgtMjVkNi00MWE2LTk5MDUtNTZiYjVmZGNlMjVjIiwiaXNzIjoiQUVNRVQiLCJpYXQiOjE3NTgxMDMxMjAsInVzZXJJZCI6ImRkMWM2ZWY4LTI1ZDYtNDFhNi05OTA1LTU2YmI1ZmRjZTI1YyIsInJvbGUiOiIifQ.Ua4WLduZLsoyi-KfUUCSeOFnRR41bvE0-Patlh-5W_w'] = api_key
#!/usr/bin/env python3
"""
AEMET Weather Data Fetcher and Organizer
Fetches weather data from AEMET API and organizes it into structured files
"""

import requests
import json
import csv
import pandas as pd
from datetime import datetime
import os
from typing import Dict, Any, List

class AEMETDataProcessor:
    def __init__(self, api_key: str = None):
        """
        Initialize the AEMET data processor
        
        Args:
            api_key: AEMET API key (if required for some endpoints)
        """
        self.api_key = api_key
        self.headers = {
            'User-Agent': 'AEMET-Data-Fetcher/1.0',
            'Accept': 'application/json'
        }
        if api_key:
            self.headers['eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJyb3VtaXNzYW1vdWFsaWRAZ21haWwuY29tIiwianRpIjoiZGQxYzZlZjgtMjVkNi00MWE2LTk5MDUtNTZiYjVmZGNlMjVjIiwiaXNzIjoiQUVNRVQiLCJpYXQiOjE3NTgxMDMxMjAsInVzZXJJZCI6ImRkMWM2ZWY4LTI1ZDYtNDFhNi05OTA1LTU2YmI1ZmRjZTI1YyIsInJvbGUiOiIifQ.Ua4WLduZLsoyi-KfUUCSeOFnRR41bvE0-Patlh-5W_w'] = api_key
    
    def fetch_data_from_url(self, url: str) -> Dict[Any, Any]:
        """
        Fetch data from the given URL
        
        Args:
            url: The data URL from AEMET API response
            
        Returns:
            Dictionary containing the fetched data
        """
        try:
            response = requests.get(url, headers=self.headers, timeout=30)
            response.raise_for_status()
            
            # Try to parse as JSON
            try:
                return response.json()
            except json.JSONDecodeError:
                # If not JSON, return as text
                return {"raw_data": response.text}
                
        except requests.RequestException as e:
            print(f"Error fetching data from {url}: {e}")
            return {}
    
    def is_year_in_range(self, year_str: str, start_year: int = 2000, end_year: int = 2020) -> bool:
        """
        Check if a year is within the specified range
        
        Args:
            year_str: Year as string
            start_year: Start year of range (inclusive)
            end_year: End year of range (inclusive)
            
        Returns:
            True if year is in range, False otherwise
        """
        try:
            year = int(year_str)
            return start_year <= year <= end_year
        except (ValueError, TypeError):
            return False
    
    def process_temperature_extremes(self, data: Dict[Any, Any], year_filter: bool = True, start_year: int = 2000, end_year: int = 2020) -> Dict[str, Any]:
        """
        Process temperature extremes data into structured format
        
        Args:
            data: Raw temperature data from AEMET
            year_filter: Whether to filter by year range
            start_year: Start year for filtering (inclusive)
            end_year: End year for filtering (inclusive)
            
        Returns:
            Processed and structured data
        """
        if not data:
            return {}
        
        # Month names for better readability
        month_names = [
            "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
            "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre", "Absoluto"
        ]
        
        processed = {
            "station_info": {
                "indicativo": data.get("indicativo", ""),
                "nombre": data.get("nombre", ""),
                "ubicacion": data.get("ubicacion", ""),
                "codigo": data.get("codigo", "")
            },
            "filter_info": {
                "year_filter_applied": year_filter,
                "start_year": start_year if year_filter else None,
                "end_year": end_year if year_filter else None
            },
            "temperature_data": {}
        }
        
        # Process minimum temperatures
        if "temMin" in data:
            processed["temperature_data"]["minimum_temps"] = []
            for i, (temp, day, year, month_name) in enumerate(zip(
                data.get("temMin", []),
                data.get("diaMin", []),
                data.get("anioMin", []),
                month_names
            )):
                # Apply year filter - skip absolute values filtering for now
                if not year_filter or i == 12 or self.is_year_in_range(year, start_year, end_year):
                    processed["temperature_data"]["minimum_temps"].append({
                        "month": month_name,
                        "month_number": i + 1 if i < 12 else "absolute",
                        "temperature_celsius": float(temp) / 10 if temp.replace('-', '').isdigit() else temp,  # Convert from tenths
                        "day": day,
                        "year": year,
                        "in_range": self.is_year_in_range(year, start_year, end_year) if year_filter else True
                    })
        
        # Process maximum temperatures
        if "temMax" in data:
            processed["temperature_data"]["maximum_temps"] = []
            for i, (temp, day, year, month_name) in enumerate(zip(
                data.get("temMax", []),
                data.get("diaMax", []),
                data.get("anioMax", []),
                month_names
            )):
                if not year_filter or i == 12 or self.is_year_in_range(year, start_year, end_year):
                    processed["temperature_data"]["maximum_temps"].append({
                        "month": month_name,
                        "month_number": i + 1 if i < 12 else "absolute",
                        "temperature_celsius": float(temp) / 10 if temp.isdigit() else temp,
                        "day": day,
                        "year": year,
                        "in_range": self.is_year_in_range(year, start_year, end_year) if year_filter else True
                    })
        
        # Process mean low temperatures
        if "temMedBaja" in data:
            processed["temperature_data"]["mean_low_temps"] = []
            for i, (temp, year, month_name) in enumerate(zip(
                data.get("temMedBaja", []),
                data.get("anioMedBaja", []),
                month_names
            )):
                if not year_filter or i == 12 or self.is_year_in_range(year, start_year, end_year):
                    processed["temperature_data"]["mean_low_temps"].append({
                        "month": month_name,
                        "month_number": i + 1 if i < 12 else "absolute",
                        "temperature_celsius": float(temp) / 10 if temp.isdigit() else temp,
                        "year": year,
                        "in_range": self.is_year_in_range(year, start_year, end_year) if year_filter else True
                    })
        
        # Process mean high temperatures
        if "temMedAlta" in data:
            processed["temperature_data"]["mean_high_temps"] = []
            for i, (temp, year, month_name) in enumerate(zip(
                data.get("temMedAlta", []),
                data.get("anioMedAlta", []),
                month_names
            )):
                if not year_filter or i == 12 or self.is_year_in_range(year, start_year, end_year):
                    processed["temperature_data"]["mean_high_temps"].append({
                        "month": month_name,
                        "month_number": i + 1 if i < 12 else "absolute",
                        "temperature_celsius": float(temp) / 10 if temp.isdigit() else temp,
                        "year": year,
                        "in_range": self.is_year_in_range(year, start_year, end_year) if year_filter else True
                    })
        
        # Process mean minimum temperatures
        if "temMedMin" in data:
            processed["temperature_data"]["mean_minimum_temps"] = []
            for i, (temp, year, month_name) in enumerate(zip(
                data.get("temMedMin", []),
                data.get("anioMedMin", []),
                month_names
            )):
                if not year_filter or i == 12 or self.is_year_in_range(year, start_year, end_year):
                    processed["temperature_data"]["mean_minimum_temps"].append({
                        "month": month_name,
                        "month_number": i + 1 if i < 12 else "absolute",
                        "temperature_celsius": float(temp) / 10 if temp.replace('-', '').isdigit() else temp,
                        "year": year,
                        "in_range": self.is_year_in_range(year, start_year, end_year) if year_filter else True
                    })
        
        # Process mean maximum temperatures
        if "temMedMax" in data:
            processed["temperature_data"]["mean_maximum_temps"] = []
            for i, (temp, year, month_name) in enumerate(zip(
                data.get("temMedMax", []),
                data.get("anioMedMax", []),
                month_names
            )):
                if not year_filter or i == 12 or self.is_year_in_range(year, start_year, end_year):
                    processed["temperature_data"]["mean_maximum_temps"].append({
                        "month": month_name,
                        "month_number": i + 1 if i < 12 else "absolute",
                        "temperature_celsius": float(temp) / 10 if temp.isdigit() else temp,
                        "year": year,
                        "in_range": self.is_year_in_range(year, start_year, end_year) if year_filter else True
                    })
        
        return processed
    
    def process_all_data(self, data: Dict[Any, Any], year_filter: bool = True, start_year: int = 2000, end_year: int = 2020) -> Dict[str, Any]:
        """
        Process all types of weather data (temperature, precipitation, etc.)
        
        Args:
            data: Raw weather data from AEMET
            year_filter: Whether to filter by year range
            start_year: Start year for filtering
            end_year: End year for filtering
            
        Returns:
            Processed data with appropriate data type
        """
        if not data:
            return {}
        
        # Check what type of data this is based on available fields
        if "temMin" in data or "temMax" in data:
            # Temperature data
            return self.process_temperature_extremes(data, year_filter, start_year, end_year)
        elif "maxDiasMesPrec" in data or "precMaxDia" in data:
            # Precipitation data
            return self.process_precipitation_extremes(data, year_filter, start_year, end_year)
        else:
            # Unknown data type - return as is with basic processing
            return {
                "station_info": {
                    "indicativo": data.get("indicativo", ""),
                    "nombre": data.get("nombre", ""),
                    "ubicacion": data.get("ubicacion", ""),
                    "codigo": data.get("codigo", "")
                },
                "filter_info": {
                    "year_filter_applied": year_filter,
                    "start_year": start_year if year_filter else None,
                    "end_year": end_year if year_filter else None
                },
                "raw_data": data
            }
        """
        Process precipitation extremes data into structured format
        
        Args:
            data: Raw precipitation data from AEMET
            year_filter: Whether to filter by year range
            start_year: Start year for filtering (inclusive)
            end_year: End year for filtering (inclusive)
            
        Returns:
            Processed and structured data
        """
        if not data:
            return {}
        
        # Month names for better readability
        month_names = [
            "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
            "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre", "Absoluto"
        ]
        
        processed = {
            "station_info": {
                "indicativo": data.get("indicativo", ""),
                "nombre": data.get("nombre", ""),
                "ubicacion": data.get("ubicacion", ""),
                "codigo": data.get("codigo", "")
            },
            "filter_info": {
                "year_filter_applied": year_filter,
                "start_year": start_year if year_filter else None,
                "end_year": end_year if year_filter else None
            },
            "precipitation_data": {},
            "snow_data": {},
            "storm_data": {}
        }
        
        # Process precipitation days
        if "maxDiasMesPrec" in data:
            processed["precipitation_data"]["max_days"] = []
            for i, (days, year, month_name) in enumerate(zip(
                data.get("maxDiasMesPrec", []),
                data.get("anioMaxDiasMesPrec", []),
                month_names
            )):
                # Apply year filter if enabled
                if not year_filter or self.is_year_in_range(year, start_year, end_year) or i == 12:  # Always include absolute (index 12)
                    processed["precipitation_data"]["max_days"].append({
                        "month": month_name,
                        "month_number": i + 1 if i < 12 else "absolute",
                        "max_days": days,
                        "year": year
                    })
        
        # Process snow days
        if "maxDiasMesNieve" in data:
            processed["snow_data"]["max_days"] = []
            for i, (days, year, month_name) in enumerate(zip(
                data.get("maxDiasMesNieve", []),
                data.get("anioMaxDiasMesNieve", []),
                month_names
            )):
                if not year_filter or self.is_year_in_range(year, start_year, end_year) or i == 12:
                    processed["snow_data"]["max_days"].append({
                        "month": month_name,
                        "month_number": i + 1 if i < 12 else "absolute",
                        "max_days": days,
                        "year": year
                    })
        
        # Process storm days
        if "maxDiasMesTormenta" in data:
            processed["storm_data"]["max_days"] = []
            for i, (days, year, month_name) in enumerate(zip(
                data.get("maxDiasMesTormenta", []),
                data.get("anioMaxDiasMesTormenta", []),
                month_names
            )):
                if not year_filter or self.is_year_in_range(year, start_year, end_year) or i == 12:
                    processed["storm_data"]["max_days"].append({
                        "month": month_name,
                        "month_number": i + 1 if i < 12 else "absolute",
                        "max_days": days,
                        "year": year
                    })
        
        # Process daily precipitation maxima
        if "precMaxDia" in data:
            processed["precipitation_data"]["daily_maxima"] = []
            for i, (prec, day, year, month_name) in enumerate(zip(
                data.get("precMaxDia", []),
                data.get("diaMaxDia", []),
                data.get("anioMaxDia", []),
                month_names
            )):
                if not year_filter or self.is_year_in_range(year, start_year, end_year) or i == 12:
                    processed["precipitation_data"]["daily_maxima"].append({
                        "month": month_name,
                        "month_number": i + 1 if i < 12 else "absolute",
                        "precipitation_mm": float(prec) / 10 if prec.isdigit() else prec,  # Convert from tenths of mm
                        "day": day,
                        "year": year
                    })
        
        # Process monthly precipitation maxima
        if "precMaxMen" in data:
            processed["precipitation_data"]["monthly_maxima"] = []
            for i, (prec, year, month_name) in enumerate(zip(
                data.get("precMaxMen", []),
                data.get("anioMaxMen", []),
                month_names
            )):
                if not year_filter or self.is_year_in_range(year, start_year, end_year) or i == 12:
                    processed["precipitation_data"]["monthly_maxima"].append({
                        "month": month_name,
                        "month_number": i + 1 if i < 12 else "absolute",
                        "precipitation_mm": float(prec) / 10 if prec.isdigit() else prec,
                        "year": year
                    })
        
        # Process monthly precipitation minima
        if "precMinMen" in data:
            processed["precipitation_data"]["monthly_minima"] = []
            for i, (prec, year, month_name) in enumerate(zip(
                data.get("precMinMen", []),
                data.get("anioMinMes", []),
                month_names
            )):
                if not year_filter or self.is_year_in_range(year, start_year, end_year) or i == 12:
                    processed["precipitation_data"]["monthly_minima"].append({
                        "month": month_name,
                        "month_number": i + 1 if i < 12 else "absolute",
                        "precipitation_mm": float(prec) / 10 if prec.isdigit() else prec,
                        "year": year
                    })
        
        return processed
    
    def save_to_json(self, data: Dict[Any, Any], filename: str):
        """Save data to JSON file"""
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print(f"Data saved to {filename}")
    
    def save_to_csv(self, data: Dict[Any, Any], base_filename: str):
        """Save data to CSV files (separate files for different data types)"""
        if not data or "station_info" not in data:
            return
        
        station_name = data["station_info"].get("nombre", "unknown").lower().replace(" ", "_")
        
        # Save precipitation data
        if "precipitation_data" in data:
            prec_data = data["precipitation_data"]
            
            # Daily maxima
            if "daily_maxima" in prec_data:
                df_daily = pd.DataFrame(prec_data["daily_maxima"])
                filename = f"{base_filename}_{station_name}_daily_precipitation_maxima.csv"
                df_daily.to_csv(filename, index=False, encoding='utf-8')
                print(f"Daily precipitation maxima saved to {filename}")
            
            # Monthly maxima
            if "monthly_maxima" in prec_data:
                df_monthly_max = pd.DataFrame(prec_data["monthly_maxima"])
                filename = f"{base_filename}_{station_name}_monthly_precipitation_maxima.csv"
                df_monthly_max.to_csv(filename, index=False, encoding='utf-8')
                print(f"Monthly precipitation maxima saved to {filename}")
            
            # Monthly minima
            if "monthly_minima" in prec_data:
                df_monthly_min = pd.DataFrame(prec_data["monthly_minima"])
                filename = f"{base_filename}_{station_name}_monthly_precipitation_minima.csv"
                df_monthly_min.to_csv(filename, index=False, encoding='utf-8')
                print(f"Monthly precipitation minima saved to {filename}")
        
        # Save snow data
        if "snow_data" in data and "max_days" in data["snow_data"]:
            df_snow = pd.DataFrame(data["snow_data"]["max_days"])
            filename = f"{base_filename}_{station_name}_snow_days_maxima.csv"
            df_snow.to_csv(filename, index=False, encoding='utf-8')
            print(f"Snow days maxima saved to {filename}")
        
        # Save storm data
        if "storm_data" in data and "max_days" in data["storm_data"]:
            df_storm = pd.DataFrame(data["storm_data"]["max_days"])
            filename = f"{base_filename}_{station_name}_storm_days_maxima.csv"
            df_storm.to_csv(filename, index=False, encoding='utf-8')
            print(f"Storm days maxima saved to {filename}")
    
    def save_to_excel(self, data: Dict[Any, Any], filename: str):
        """Save all data to a single Excel file with multiple sheets"""
        if not data or "station_info" not in data:
            return
        
        with pd.ExcelWriter(filename, engine='openpyxl') as writer:
            # Station info sheet
            station_df = pd.DataFrame([data["station_info"]])
            station_df.to_excel(writer, sheet_name='Station_Info', index=False)
            
            # Precipitation data sheets
            if "precipitation_data" in data:
                prec_data = data["precipitation_data"]
                
                if "daily_maxima" in prec_data:
                    df_daily = pd.DataFrame(prec_data["daily_maxima"])
                    df_daily.to_excel(writer, sheet_name='Daily_Prec_Maxima', index=False)
                
                if "monthly_maxima" in prec_data:
                    df_monthly_max = pd.DataFrame(prec_data["monthly_maxima"])
                    df_monthly_max.to_excel(writer, sheet_name='Monthly_Prec_Maxima', index=False)
                
                if "monthly_minima" in prec_data:
                    df_monthly_min = pd.DataFrame(prec_data["monthly_minima"])
                    df_monthly_min.to_excel(writer, sheet_name='Monthly_Prec_Minima', index=False)
            
            # Snow data sheet
            if "snow_data" in data and "max_days" in data["snow_data"]:
                df_snow = pd.DataFrame(data["snow_data"]["max_days"])
                df_snow.to_excel(writer, sheet_name='Snow_Days_Maxima', index=False)
            
            # Storm data sheet
            if "storm_data" in data and "max_days" in data["storm_data"]:
                df_storm = pd.DataFrame(data["storm_data"]["max_days"])
                df_storm.to_excel(writer, sheet_name='Storm_Days_Maxima', index=False)
        
        print(f"All data saved to Excel file: {filename}")

def main():
    """
    Main function to fetch data from AEMET URLs and organize into files
    """
    # URLs from your latest API response
    datos_url = "https://opendata.aemet.es/opendata/sh/e70f231e"
    meta_url = "https://opendata.aemet.es/opendata/sh/f47d8744"
    # Initialize processor
    processor = AEMETDataProcessor()
    
    # Create output directory
    output_dir = "aemet_data_output"
    os.makedirs(output_dir, exist_ok=True)
    
    print("Fetching weather data from AEMET...")
    print(f"Data URL: {datos_url}")
    print(f"Metadata URL: {meta_url}")
    
    # Fetch main data
    raw_data = processor.fetch_data_from_url(datos_url)
    
    # Fetch metadata
    metadata = processor.fetch_data_from_url(meta_url)
    
    if raw_data:
        print("✓ Successfully fetched weather data")
        print("Processing data...")
        processed_data = processor.process_temperature_extremes(raw_data)
        
        # Get current timestamp for filenames
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # Save in different formats
        print("Saving data to files...")
        
        # JSON format (complete structured data)
        json_filename = os.path.join(output_dir, f"aemet_precipitation_extremes_{timestamp}.json")
        processor.save_to_json(processed_data, json_filename)
        
        # CSV format (separate files for each data type)
        csv_base = os.path.join(output_dir, f"aemet_{timestamp}")
        processor.save_to_csv(processed_data, csv_base)
        
        # Excel format (all data in one file with multiple sheets)
        excel_filename = os.path.join(output_dir, f"aemet_precipitation_extremes_{timestamp}.xlsx")
        processor.save_to_excel(processed_data, excel_filename)
        
        # Save raw data for reference
        raw_filename = os.path.join(output_dir, f"aemet_raw_data_{timestamp}.json")
        processor.save_to_json(raw_data, raw_filename)
        
        # Save metadata if available
        if metadata:
            print("✓ Successfully fetched metadata")
            meta_filename = os.path.join(output_dir, f"aemet_metadata_{timestamp}.json")
            processor.save_to_json(metadata, meta_filename)
        
        print(f"\n✓ All files saved to: {output_dir}")
        print("Files created:")
        print(f"  • Raw data: {os.path.basename(raw_filename)}")
        print(f"  • Processed data (JSON): {os.path.basename(json_filename)}")
        print(f"  • Excel file: {os.path.basename(excel_filename)}")
        print(f"  • CSV files: Multiple files with prefix 'aemet_{timestamp}'")
        if metadata:
            print(f"  • Metadata: {os.path.basename(meta_filename)}")
        print("\nProcessing completed successfully!")
        
        # Display basic station info
        if "station_info" in processed_data:
            station = processed_data["station_info"]
            print(f"\nStation Information:")
            print(f"  Name: {station.get('nombre', 'N/A')}")
            print(f"  Location: {station.get('ubicacion', 'N/A')}")
            print(f"  Code: {station.get('codigo', 'N/A')}")
            print(f"  Indicator: {station.get('indicativo', 'N/A')}")
    
    else:
        print("❌ Failed to fetch data from the provided URL")
        print("Please check:")
        print("  • Internet connection")
        print("  • URL validity")
        print("  • AEMET service availability")

if __name__ == "__main__":
    main()